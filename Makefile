DOCKER_USER=rstudio
DOCKER_UID=$(shell id -u)

PROJECT_USER=kaybenleroll
PROJECT_NAME=insurance-modelling
PROJECT_LABEL=latest

IMAGE_TAG=${PROJECT_USER}/${PROJECT_NAME}:${PROJECT_LABEL}

RSTUDIO_PORT=8787

CONTAINER_NAME=modelling


### Project build targets
.SUFFIXES: .Rmd .html .dot .png

RMD_FILES  := $(wildcard *.Rmd)
HTML_FILES := $(patsubst %.Rmd,%.html,$(RMD_FILES))


all-html: $(HTML_FILES)

.Rmd.html:
	Rscript -e 'rmarkdown::render("$<")'

.dot.png: %.dot
	dot -Tpng -o$*.png $<

full_deps.dot:
	makefile2graph all-html > full_deps.dot

depgraph: full_deps.dot full_deps.png


exploring_mtpl_datasets.html: construct_mtpl_datasets.html



echo-reponame:
	echo "${REPO_NAME}"

clean-html:
	rm -rfv *.html

clean-cache:
	rm -rfv *_cache
	rm -rfv *_files


docker-build-image: Dockerfile
	docker build -t ${IMAGE_TAG} -f Dockerfile .

docker-run:
	docker run --rm -d \
	  -p ${RSTUDIO_PORT}:8787 \
	  -v "${PWD}":"/home/${DOCKER_USER}/${PROJECT_NAME}":rw \
	  -e USER=${DOCKER_USER} \
	  -e USERID=${DOCKER_UID} \
	  -e PASSWORD=quickpass \
	  --name ${CONTAINER_NAME} \
	  ${IMAGE_TAG}

docker-bash:
	docker exec -it -u ${DOCKER_USER} ${CONTAINER_NAME} bash



docker-stop:
	docker stop ${CONTAINER_NAME}

docker-clean:
	docker rm $(shell docker ps -q -a)

docker-login:
	cat $(HOME)/.dockerpass | docker login -u kaybenleroll --password-stdin

docker-pull:
	docker pull ${IMAGE_TAG}

docker-push:
	docker push ${IMAGE_TAG}
