![Healm Chart](https://storage.ghost.io/c/5f/2f/5f2f4d20-2abf-4534-8d40-7aa233aedd43/content/images/2026/04/image-32.png)

```helm create my-flask-app```

helm search hub searches the Artifact Hub, which lists helm charts from dozens of different repositories.

Make sure that the chart is valid an there are no indentation errros. 
provide the chart directory path
```helm lint .```

Render the templates, Run 

```helm template .```

To test it with a dry run, run
```helm  install  --dry-run=client  my-flask-app flask-app release-name chart_name```

Run ```helm``` commands from the outside of the ```helm-chart``` folder. 

Load the docker image in the kind cluster, if you are usign the kind cluster. 

To install the chart run 
```helm install release_name chart_name```
```helm install release_name chart_name --values=values.yaml```

run
```helm list```
to see the details

To upgrade. run 
```helm upgrade release_name chart_name```

To rollback to old deployment 
```helm rollback release_name```
```helm rollback release_name revision_number```

helm diff plugin
![helm diff plugin](https://github.com/databus23/helm-diff)

**Note**: If we used the different namespaces in kubernetes manifests and while applying the helm chart the helm details can be view from the namespace used while applying the helm commands. The resources will be the namespace used in the kubernetes manifests. 

To uninstall
```helm uninstall release-name```