.PHONY: build

build:
	IMAGE_NAME=jnovack/autossh:dev hooks/build

clean:
	docker rmi jnovack/autossh:dev
