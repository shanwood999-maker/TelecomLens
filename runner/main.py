"""TelecomLens runner: scrape prices/stock, run evening-peak tests, store raw results.

Runs on Fly.io, separate from the Next.js site. Triggered at 20:00, 21:00, 22:00 CST.
"""
import os
from apscheduler.schedulers.blocking import BlockingScheduler

from adapters import PROVIDER_ADAPTERS
from tester import run_test_for_plan

DATABASE_URL = os.environ["DATABASE_URL"]


def scrape_all():
    """Scrape every provider, diff HTML, queue a fix task on parse failure."""
    for adapter in PROVIDER_ADAPTERS:
        try:
            plans = adapter.scrape()
            adapter.upsert_plans(plans)
        except Exception as exc:  # noqa: BLE001 - triaged by the Bot, not retried blindly
            adapter.record_failure(str(exc))


def test_all():
    """Run the evening-peak test slot for every in-stock plan."""
    for adapter in PROVIDER_ADAPTERS:
        for plan in adapter.in_stock_plans():
            run_test_for_plan(plan)


def daily_job():
    scrape_all()
    test_all()


if __name__ == "__main__":
    scheduler = BlockingScheduler(timezone="Asia/Shanghai")
    for hour in (20, 21, 22):
        scheduler.add_job(daily_job, "cron", hour=hour, minute=0)
    scheduler.start()
