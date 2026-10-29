.PHONY: check style style-check help test document build-site build-data lint
ALL: style document check

style:
	@air format R/

style-check:
	@air format --check R/

lint:
	@jarl check R

check:
	@Rscript -e "devtools::check(error_on = 'warning', cran = TRUE)"

test:
	@Rscript -e "devtools::test()"

document:
	@Rscript -e "devtools::document()"

build-site:
	@Rscript -e "pkgdown::build_site()"

build-data:
	@Rscript -e "devtools::load_all(); for (file in list.files('data-raw', full.names = TRUE)) source(file)"

help:
	@echo "Available commands:"
	@echo "  make style       - Auto-format all files in /R with air"
	@echo "  make style-check - Check formatting (fails if unformatted)"
	@echo "  make lint        - Run jarl check R"
	@echo "  make check       - Run devtools::check()"
	@echo "  make test        - Run tests"
	@echo "  make document    - Build roxygen docs"
	@echo "  make build-site  - Build pkgdown site"
	@echo "  make build-data  - Build data objects from data-raw"
