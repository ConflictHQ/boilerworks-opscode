.PHONY: fmt validate init-dev plan-dev apply-dev init-stg plan-stg apply-stg init-prd plan-prd apply-prd bootstrap

# Formatting & validation
fmt:
	./run.sh fmt

validate:
	./run.sh validate

# AWS Dev
init-dev:
	./run.sh init aws dev

plan-dev:
	./run.sh plan aws dev

apply-dev:
	./run.sh apply aws dev

# AWS Stg
init-stg:
	./run.sh init aws stg

plan-stg:
	./run.sh plan aws stg

apply-stg:
	./run.sh apply aws stg

# AWS Prd
init-prd:
	./run.sh init aws prd

plan-prd:
	./run.sh plan aws prd

apply-prd:
	./run.sh apply aws prd

# Bootstrap
bootstrap:
	./run.sh bootstrap aws
