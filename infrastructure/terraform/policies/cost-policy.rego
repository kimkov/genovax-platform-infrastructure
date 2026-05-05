package infracost

# Cost warning of more than $100 increase
warn[msg] {
	diff := to_number(input.diffTotalMonthlyCost)
	diff > 100
	msg := sprintf("Please note: This PR increases your monthly costs by $%v", [diff])
}

# PR blocking when the $500 threshold is exceeded (requires FinOps approval)
deny[msg] {
    diff := to_number(input.diffTotalMonthlyCost)
    diff > 500
    msg := sprintf("ERROR: Cost growth forecast ($%v) exceeds $500 limit. Contact FinOps for approval. ", [diff])
}