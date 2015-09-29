init:

	Rscript requirements.R

fetch_data:

	wget http://enigma-public.s3.amazonaws.com/projects/smoke-alarm-risk/data/acs-bg-at-risk-population.csv \
		-O data/acs-bg-at-risk-population.csv

	wget http://enigma-public.s3.amazonaws.com/projects/smoke-alarm-risk/data/acs-bg-population.csv \
		-O data/acs-bg-population.csv

	wget http://enigma-public.s3.amazonaws.com/projects/smoke-alarm-risk/data/acs-bg-pop-density.csv \
		-O data/acs-bg-pop-density.csv

	wget http://enigma-public.s3.amazonaws.com/projects/smoke-alarm-risk/data/msa80-bg.csv \
		-O data/msa80-bg.csv

	wget http://enigma-public.s3.amazonaws.com/projects/smoke-alarm-risk/data/ahs.csv \
		-O data/ahs.csv

	wget http://enigma-public.s3.amazonaws.com/projects/smoke-alarm-risk/data/acs.csv \
		-O data/acs.csv

model:

	Rscript -e 'knitr::knit2html("./index.Rmd")'


figures:

	rm paper/*.png
	cp figure/*.png paper/

view: 

	python -m SimpleHTTPServer

s3:

	s3cmd put data/smoke-alarm-risk-scores.csv s3://enigma-public/projects/smoke-alarm-risk/data/smoke-alarm-risk-scores.csv 
	s3cmd setacl s3://enigma-public/projects/smoke-alarm-risk/data/smoke-alarm-risk-scores.csv --acl-public --recursive
