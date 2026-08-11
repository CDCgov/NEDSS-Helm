from src.db_transaction import Transaction
from src.models import ReportResult, Table


def execute(
    trx: Transaction,
    subset_query: str,
    **kwargs,
) -> ReportResult:
    """Simple example of a Python Report Library."""

    content: Table = trx.query(subset_query)

    return ReportResult(content=content)
