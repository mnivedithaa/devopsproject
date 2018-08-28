build-image:
	docker build -t mnivedithaa/devopsproject devopsproject

publish-image:
	docker push mnivedithaa/devopsproject

platform:
	@cd terraform; terraform init;terraform get;terraform apply -var-file=dc.tfvars -lock=false

destroyplatform:
	@cd terraform; terraform destroy -var-file=dc.tfvars
