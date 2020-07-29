DOCKER_USER=rstudio
DOCKER_UID=$(shell id -u)

PROJECT_USER=kaybenleroll
PROJECT_NAME=insurance-modelling
PROJECT_LABEL=latest

IMAGE_TAG=${PROJECT_USER}/${PROJECT_NAME}:${PROJECT_LABEL}

RSTUDIO_PORT=8787

CONTAINER_NAME=modelling



RMD_FILES  := $(wildcard *.Rmd)
HTML_FILES := $(patsubst %.Rmd,%.html,$(RMD_FILES))


all-html: $(HTML_FILES)



%.html: %.Rmd
	Rscript -e 'rmarkdown::render("$<")'



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

docker-stop:
	docker stop $(shell docker ps -q -a)

docker-clean:
	docker rm $(shell docker ps -q -a)

docker-login:
	cat $(HOME)/.dockerpass | docker login -u kaybenleroll --password-stdin

docker-pull:
	docker pull ${IMAGE_TAG}

docker-push:
	docker push ${IMAGE_TAG}
