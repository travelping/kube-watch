# Kube Watch

[![License: Apache-2.0][Apache 2.0 Badge]][Apache 2.0]
[![GitHub Release Badge]][GitHub Releases]

A [Docker] image packed tool for watching a [Kubernetes] object or its part
invoking a specified handling executable on a change.

## Usage

For better usage understanding we start with an example.

### Example

Consider you have a [ConfigMap]:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-watch-example-configmap
data:
  fruits: orange,apple,banana
```

And you want to run a handling executable on every change of the "fruits" field.
The [Example Manifest] creates all the needed workloads (including the mentioned
ConfigMap) to demonstrate how could it be done with the tool.

Along with the ConfigMap mentioned above the manifest creates another ConfigMap
representing an example executable which is a script like this:

```
#!/bin/bash

echo "Current fruits: $1"
echo "Previous fruits: $2"
```

Handling executable is invoked with two parameters: the current state of a field
and the previous one. Thus this example script just prints out both states.

To connect this script and the target ConfigMap field, the manifest runs the
Kube Watch based container as a [Deployment].

To be able watching the ConfigMap, the Deployment uses a [Service Account] bound
to the corresponding role. The [Role] and the [RoleBinding] are also created.

To see the example in action please apply the manifest (applies to the current
namespace):

```
$ kubectl apply -f https://raw.githubusercontent.com/travelping/kube-watch/master/manifests/example.yaml
```

Let's look at the Kube Watch pod logs:

```
$ POD=$(kubectl get po -l app=kube-watch-example -o jsonpath={.items[0].metadata.name})
$ kubectl logs $POD -f
...
### Channel data ###
orange,apple,banana
###
### Channel data diff ###
@@ -0,0 +1 @@
+orange,apple,banana
\ No newline at end of file
###
Handling channel data with /usr/share/kube-watch/handler...
Current fruits: orange,apple,banana
Previous fruits:
...
```

In "Channel data" we can see current state of the target content. The "Channel
data diff" provides difference with the previous version. The first event
basically says: "there was nothing, and then three fruits appeared" and our
example script behaves accordingly.

If we continue watching logs and change our fruits basket:

```
$ kubectl patch configmap kube-watch-example-configmap -p '{"data":{"fruits":"orange,mango,banana"}}'
configmap/kube-watch-example-configmap patched
```

We will see the following log output:

```
### Channel data ###
orange,mango,banana
###
### Channel data diff ###
@@ -1 +1 @@
-orange,apple,banana
\ No newline at end of file
+orange,mango,banana
\ No newline at end of file
###
Handling channel data with /usr/share/kube-watch/handler...
Current fruits: orange,mango,banana
Previous fruits: orange,apple,banana
...
```

### Your Own Solution

Your own solution should not necessarily be a deployment and mount your handling
executable as a ConfigMap. For example, you can build your own Docker image from
this one with all the needed executables baked in. Or use [DaemonSet] instead of
Deployment.

All you need to know is the base image usage. If you run it without arguments
it provides basic idea:

```
$ docker run --rm quay.io/travelping/kube-watch
Usage: kube-watch run <Type> <[Namespace/]Name> [Options]
       kube-watch version

Options:
    -j,--jsonpath=<Jsonpath>  Path to the object field (default: {})
    -h,--handler=<Handler>    Handler (default: /usr/share/kube-watch/handler)
```

Along with the correctly specified arguments for the "kube-watch" make sure the
following:

* the "kubectl" is available in the container (either mounted from the node or
  baked into the next layer image)
* running pod has enough permissions to watch the target object (see the Role
  in the [Example Manifest])
* handler executable is available in the container.

You can also have several targets being watched. In this case you would need an
accordingly configured container per target.

## License

Copyright 2019 Travelping GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

<!-- Links -->

[Docker]: https://docs.docker.com
[ConfigMap]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap
[DaemonSet]: https://kubernetes.io/docs/concepts/workloads/controllers/daemonset
[Deployment]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment
[Kubernetes]: https://kubernetes.io
[Role]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole
[RoleBinding]: https://kubernetes.io/docs/reference/access-authn-authz/rbac/#rolebinding-and-clusterrolebinding
[Service Account]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account
[Example Manifest]: manifests/example.yaml

<!-- Badges -->

[Apache 2.0]: https://opensource.org/licenses/Apache-2.0
[Apache 2.0 Badge]: https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg?style=flat-square
[GitHub Releases]: https://github.com/travelping/kube-watch/releases
[GitHub Release Badge]: https://img.shields.io/github/release/travelping/kube-watch/all.svg?style=flat-square
