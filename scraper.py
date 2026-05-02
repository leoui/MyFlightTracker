#!/usr/bin/env python3
"""
scraper.py – Google Flights scraper (anti-detection version)
Usage:
  Single date:  scraper.py CGK DPS 2026-06-10 economy
  Batch mode:   scraper.py CGK DPS 2026-08-01 2026-08-31 economy

Output: JSON array of flight objects to stdout
"""

import sys
import re
import json
import time
import base64
import random
import argparse
from datetime import datetime, timedelta
from typing import Optional

# ---------------------------------------------------------------------------
# Config — tune these to be "human speed"
# ---------------------------------------------------------------------------

MIN_DELAY = 5.0     # seconds minimum between requests
MAX_DELAY = 18.0    # seconds maximum between requests
SCROLL_PROB = 0.6   # probability of doing a scroll action
CLICK_PROB = 0.15   # probability of clicking a random UI element
MAX_RETRIES = 2     # retries per date if no results
RETRY_DELAY = 25.0  # wait before retry

USER_AGENTS = [
    # Chrome on macOS (recent)
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
    # Firefox on macOS
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:126.0) Gecko/20100101 Firefox/126.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:125.0) Gecko/20100101 Firefox/125.0",
    # Safari on macOS
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.3 Safari/605.1.15",
    # Chrome on Windows (to vary even more)
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
]

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

AIRLINE_MAP = {
    'lion air': 'JT', 'lion': 'JT',
    'indonesia airasia': 'QZ', 'airasia': 'QZ',
    'batik air': 'ID', 'batik': 'ID',
    'garuda indonesia': 'GA', 'garuda': 'GA',
    'sriwijaya air': 'SJ', 'sriwijaya': 'SJ',
    'wings air': 'IW', 'wings': 'IW',
    'citilink indonesia': 'QG', 'citilink': 'QG',
    'transnusa': 'TN',
    'super air jet': 'IU', 'superair': 'IU',
    'pelita air': 'IP', 'pelita': 'IP',
    'nam air': 'IN',
    'singapore airlines': 'SQ',
    'malaysia airlines': 'MH',
    'emirates': 'EK',
    'qatar airways': 'QR',
    'thai airways': 'TG',
    'cathay pacific': 'CX',
    'japan airlines': 'JL',
    'ana': 'NH',
    'korean air': 'KE',
    'eva air': 'BR',
    'china airlines': 'CI',
}

CABIN_PARAM = {'economy': 1, 'business': 2, 'first': 3}


def get_airline_code(name: str) -> str:
    lower = name.lower().strip()
    for k in sorted(AIRLINE_MAP, key=len, reverse=True):
        if k in lower:
            return AIRLINE_MAP[k]
    return lower[:2].upper() if len(lower) >= 2 else 'XX'


def parse_idr(text: str) -> int:
    nums = re.sub(r'[^\d]', '', text)
    return int(nums) if nums else 0


def normalize_time(t: str) -> str:
    return t.replace('.', ':')


def build_tfs(origin: str, destination: str, date: str) -> str:
    date_b = date.encode()
    origin_b = origin.encode()
    dest_b = destination.encode()
    inner = b'\x12' + bytes([len(date_b)]) + date_b
    inner += b'\x6a\x07\x08\x01\x12\x03' + origin_b
    inner += b'\x72\x07\x08\x01\x12\x03' + dest_b
    full = b'\x08\x1c\x10\x02\x1a' + bytes([len(inner)]) + inner
    return base64.b64encode(full).decode().rstrip('=')


def random_delay(min_s: float = MIN_DELAY, max_s: float = MAX_DELAY):
    """Sleep a random human-like amount of time."""
    delay = random.uniform(min_s, max_s)
    time.sleep(delay)
    return delay


def date_range(start: str, end: str):
    """Generate list of YYYY-MM-DD strings from start to end inclusive."""
    s = datetime.strptime(start, "%Y-%m-%d")
    e = datetime.strptime(end, "%Y-%m-%d")
    dates = []
    while s <= e:
        dates.append(s.strftime("%Y-%m-%d"))
        s += timedelta(days=1)
    return dates


# ---------------------------------------------------------------------------
# Human-like browser actions
# ---------------------------------------------------------------------------

def humanize_scroll(page):
    """Random scroll to appear human."""
    if random.random() > SCROLL_PROB:
        return
    scroll_amount = random.randint(100, 400)
    direction = random.choice([1, -1])
    try:
        page.mouse.wheel(0, scroll_amount * direction)
        time.sleep(random.uniform(0.3, 0.8))
        # Scroll back sometimes
        if random.random() > 0.5:
            page.mouse.wheel(0, -scroll_amount * direction * 0.6)
            time.sleep(random.uniform(0.2, 0.5))
    except Exception:
        pass


def humanize_mouse(page):
    """Move mouse to random positions."""
    try:
        w = random.randint(200, 800)
        h = random.randint(100, 500)
        page.mouse.move(w, h)
        time.sleep(random.uniform(0.1, 0.3))
    except Exception:
        pass


def humanize_viewport(page):
    """Occasionally resize viewport slightly to vary fingerprint."""
    if random.random() > 0.2:
        return
    try:
        w = random.randint(1200, 1440)
        h = random.randint(700, 900)
        page.set_viewport_size({"width": w, "height": h})
    except Exception:
        pass


# ---------------------------------------------------------------------------
# Extract flights from current page
# ---------------------------------------------------------------------------

def extract_flights(page, origin: str, destination: str, date: str, cabin: str) -> list[dict]:
    """Extract flight data from a loaded Google Flights page."""
    results = []
    cards = page.query_selector_all('li[class*="pIav2d"]')

    for card in cards:
        try:
            text = card.inner_text()
            lines = [ln.strip() for ln in text.split('\n') if ln.strip()]

            # Price
            price_line = next(
                (ln for ln in lines if ln.startswith('Rp') and re.search(r'Rp\s*[\d.]+', ln)),
                None
            )
            if not price_line:
                continue
            price = parse_idr(price_line)
            if price < 100_000 or price > 50_000_000:
                continue

            # Times
            times = re.findall(r'\b(\d{1,2}[.:]\d{2})\b', text)
            if len(times) < 2:
                continue
            dep_time = normalize_time(times[0])
            arr_time = normalize_time(times[1])

            # Airline
            airline_name = 'Unknown'
            for line in lines:
                if re.match(r'^\d{1,2}[.:]\d{2}', line):
                    continue
                if 'Rp' in line:
                    continue
                if re.match(r'^\d+$', line):
                    continue
                if line in {'–', '+', 'Langsung', 'mnt', 'jam', 'Berhenti 1', 'Berhenti 2'}:
                    continue
                if re.search(r'\d+\s*jam', line):
                    continue
                if 4 <= len(line) <= 50:
                    airline_name = re.split(r'Dioperasikan', line)[0].strip()
                    break

            airline_code = get_airline_code(airline_name)

            # Duration
            dur_m = re.search(r'(\d+)\s*jam(?:\s*(\d+)\s*mnt)?', text)
            duration_min = 0
            if dur_m:
                duration_min = int(dur_m.group(1)) * 60 + int(dur_m.group(2) or 0)

            dep_hour = int(dep_time.split(':')[0]) if ':' in dep_time else 0

            results.append({
                'origin': origin,
                'destination': destination,
                'date': date,
                'airline_code': airline_code,
                'airline_name': airline_name,
                'dep_time': dep_time,
                'arr_time': arr_time,
                'dep_hour': dep_hour,
                'price_idr': price,
                'duration_min': duration_min,
                'is_direct': 'Langsung' in text,
                'cabin': cabin,
            })
        except Exception:
            continue

    # Deduplicate
    seen: set[tuple] = set()
    unique = []
    for r in results:
        key = (r['airline_code'], r['dep_time'], r['price_idr'])
        if key not in seen:
            seen.add(key)
            unique.append(r)

    return sorted(unique, key=lambda x: x['price_idr'])


# ---------------------------------------------------------------------------
# Check if page shows CAPTCHA or block
# ---------------------------------------------------------------------------

def detect_block(page) -> str | None:
    """Check if Google is blocking us. Returns reason or None."""
    try:
        body = page.inner_text('body').lower()
    except Exception:
        return None

    block_signals = [
        ('captcha',      'CAPTCHA detected'),
        ('unusual traffic', 'Google detected unusual traffic'),
        ('automated queries', 'Automated queries blocked'),
        ('verify you are human', 'Human verification required'),
        ('robot',        'Robot detection'),
        ('blocked',      'Access blocked'),
        ('sorry, but your computer or network', 'Network block'),
    ]
    for keyword, reason in block_signals:
        if keyword in body:
            return reason
    return None


# ---------------------------------------------------------------------------
# Main scraper: batch mode with single browser session
# ---------------------------------------------------------------------------

def scrape_batch(
    origin: str,
    destination: str,
    dates: list[str],
    cabin: str = 'economy',
    progress_callback=None
) -> list[dict]:
    """
    Scrape multiple dates in a single browser session with human-like behavior.
    This is the key anti-detection method:
    - One Chromium instance stays open for all dates
    - Random delays between navigations
    - Human-like scrolling and mouse movement
    - Viewport size varies slightly
    - User-agent rotates each session
    """
    from playwright.sync_api import sync_playwright

    cabin_code = CABIN_PARAM.get(cabin, 1)
    all_flights: list[dict] = []
    ua = random.choice(USER_AGENTS)

    with sync_playwright() as p:
        # One browser for the entire batch
        browser = p.chromium.launch(
            headless=True,
            args=['--no-sandbox', '--disable-blink-features=AutomationControlled']
        )
        ctx = browser.new_context(
            locale='id-ID',
            timezone_id='Asia/Jakarta',
            user_agent=ua,
            viewport={
                "width": random.randint(1200, 1440),
                "height": random.randint(700, 900)
            }
        )

        # Inject anti-detection script before any navigation
        ctx.add_init_script("""
            Object.defineProperty(navigator, 'webdriver', { get: () => false });
            Object.defineProperty(navigator, 'languages', { get: () => ['id-ID', 'id', 'en-US', 'en'] });
            delete navigator.__proto__.webdriver;
        """)

        page = ctx.new_page()

        for idx, date in enumerate(dates):
            if progress_callback:
                progress_callback(idx + 1, len(dates), date)

            # Vary viewport slightly between dates
            humanize_viewport(page)

            tfs = build_tfs(origin, destination, date)
            url = (
                f"https://www.google.com/travel/flights/search"
                f"?tfs={tfs}&curr=IDR&hl=id&travelclass={cabin_code}"
            )

            # Human-like mouse move before navigating
            humanize_mouse(page)

            flights = []
            blocked = False

            for attempt in range(1, MAX_RETRIES + 1):
                try:
                    page.goto(url, timeout=30000, wait_until='domcontentloaded')
                except Exception:
                    time.sleep(RETRY_DELAY)
                    continue

                # Wait for content
                try:
                    page.wait_for_selector('li[class*="pIav2d"]', timeout=12000)
                except Exception:
                    try:
                        page.wait_for_selector('span:has-text("Rp")', timeout=6000)
                    except Exception:
                        pass

                time.sleep(random.uniform(1.5, 3.0))

                # Check for blocks
                block_reason = detect_block(page)
                if block_reason:
                    blocked = True
                    print(f"⚠ Block detected on {date} (attempt {attempt}): {block_reason}", file=sys.stderr)
                    # Long wait before retry
                    time.sleep(RETRY_DELAY + random.uniform(5, 15))
                    continue

                # Human-like scroll
                humanize_scroll(page)

                flights = extract_flights(page, origin, destination, date, cabin)

                if flights:
                    break  # Got data, move to next date

                if attempt < MAX_RETRIES:
                    time.sleep(random.uniform(3, 8))

            all_flights.extend(flights)

            # Log progress
            n = len(flights)
            if n > 0:
                lowest = min(f['price_idr'] for f in flights)
                print(f"  ✓ {date}: {n} flights, cheapest Rp{lowest:,}", file=sys.stderr)
            else:
                reason = "blocked" if blocked else "no results"
                print(f"  ✗ {date}: {reason}", file=sys.stderr)

            # Random delay between dates — THE KEY ANTI-DETECTION FEATURE
            if idx < len(dates) - 1:
                d = random_delay()
                print(f"  ⏳ Waiting {d:.1f}s...", file=sys.stderr)

        browser.close()

    return all_flights


def scrape_single(origin: str, destination: str, date: str, cabin: str = 'economy') -> list[dict]:
    """Legacy: scrape a single date. Delegates to batch mode."""
    return scrape_batch(origin, destination, [date], cabin)


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Scrape Google Flights prices (with anti-detection)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  Single:  scraper.py CGK DPS 2026-08-15 economy
  Batch:   scraper.py CGK DPS 2026-08-01 2026-08-31 economy
  Cabin options: economy, business, first
        """
    )
    parser.add_argument('origin', help='IATA origin code (e.g. CGK)')
    parser.add_argument('destination', help='IATA destination code (e.g. DPS)')
    parser.add_argument('date', help='Start date YYYY-MM-DD (or only date for single mode)')
    parser.add_argument('date2_or_cabin', nargs='?', default=None,
                        help='End date YYYY-MM-DD (batch) or cabin (single)')
    parser.add_argument('cabin', nargs='?', default='economy',
                        choices=['economy', 'business', 'first'])
    args = parser.parse_args()

    # Detect batch vs single mode
    dates = []
    cabin = 'economy'

    if args.date2_or_cabin and re.match(r'\d{4}-\d{2}-\d{2}', args.date2_or_cabin):
        # Batch mode: CGK DPS 2026-08-01 2026-08-31 [cabin]
        dates = date_range(args.date, args.date2_or_cabin)
        cabin = args.cabin
        print(f"📦 Batch mode: {len(dates)} dates ({args.date} → {args.date2_or_cabin})", file=sys.stderr)
    else:
        # Single mode: CGK DPS 2026-08-01 [cabin]
        dates = [args.date]
        cabin = args.date2_or_cabin if args.date2_or_cabin in ('economy', 'business', 'first') else 'economy'
        print(f"📍 Single date: {args.date}", file=sys.stderr)

    print(f"✈ {args.origin} → {args.destination} | {cabin} | {len(dates)} date(s)", file=sys.stderr)
    print(f"🔒 Anti-detection: random delays {MIN_DELAY}-{MAX_DELAY}s, UA rotation, human scroll", file=sys.stderr)

    def progress(current, total, date_str):
        print(f"\n📅 [{current}/{total}] Scraping {date_str}...", file=sys.stderr)

    flights = scrape_batch(args.origin, args.destination, dates, cabin, progress)

    # Summary
    print(f"\n{'='*60}", file=sys.stderr)
    print(f"✅ Total: {len(flights)} flights from {len(dates)} dates", file=sys.stderr)
    if flights:
        cheapest = min(f['price_idr'] for f in flights)
        print(f"💰 Cheapest overall: Rp{cheapest:,}", file=sys.stderr)
    print(f"{'='*60}", file=sys.stderr)

    # JSON to stdout
    print(json.dumps(flights, ensure_ascii=False))


if __name__ == '__main__':
    main()
