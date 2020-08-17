.PHONY: build clean hooks

build:
	docker build -t jnovack/autossh:dev .

clean:
	docker rmi jnovack/autossh:dev

# hooks copies in the newest version of any multi-arch hooks from a different repository
hooks:
	curl -Lo hooks/build https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/build
	curl -Lo hooks/post_checkout https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/post_checkout
	curl -Lo hooks/post_push https://github.com/jnovack/docker-multi-arch-hooks/raw/master/hooks/post_push
