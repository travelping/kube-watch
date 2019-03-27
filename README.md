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
  name: kube-watch-fruits
data:
  fruits: orange,apple,banana
```

And you want to run a handling executable on every change of the "fruits" field.
The [Fruits Example Manifest] creates all the needed workloads (including the
mentioned ConfigMap) to demonstrate how could it be done with the tool.

Along with the ConfigMap mentioned above the manifest creates another ConfigMap
representing an example executable which is a script like this:

```
#!/bin/bash

echo "Channel: $1"
echo "Current fruits: $2"
echo "Previous fruits: $3"
```

Handling executable is invoked with three parameters:

 * target field content exchange file (channel)
 * current content of the target field
 * previous content of the target field.

This example script just prints everything out.

To connect this script and the target ConfigMap field, the manifest runs the
Kube Watch based container as a [Deployment].

To be allowed  watching the ConfigMap, the Deployment uses a [Service Account]
bound to the corresponding role. The [Role] and the [RoleBinding] are also
created.

To see the example in action please create from the manifest (creates in the
current namespace):

```
$ kubectl create -f https://raw.githubusercontent.com/travelping/kube-watch/master/manifests/kube-watch-fruits.yaml
```

Let's look at the pod logs:

```
$ POD=$(kubectl get po -l app=kube-watch-fruits -o jsonpath={.items[0].metadata.name})
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
Channel: /var/run/kube-watch/channel
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
$ kubectl patch configmap kube-watch-fruits -p '{"data":{"fruits":"orange,mango,banana"}}'
configmap/kube-watch-fruits patched
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
Channel: /var/run/kube-watch/channel
Current fruits: orange,mango,banana
Previous fruits: orange,apple,banana
...
```

Delete the example workloads:

```
$ kubectl delete -f https://raw.githubusercontent.com/travelping/kube-watch/master/manifests/kube-watch-fruits.yaml
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
Usage: kube-watch object <Object> <[Namespace/]Name> [Options]
       kube-watch file <FileName> [Options]
       kube-watch version

Options:
    -a,--all-namespaces       Watch objects in all namespaces
    -l,--label=<Label>        Filter objects with label
    -j,--jsonpath=<Jsonpath>  Path to the object field (default: {})
    -c,--channel=<Channel>    Channel (default: /var/run/kube-watch/channel)
    -h,--handler=<Handler>    Handler (default: /usr/share/kube-watch/handler)
```

Along with the correctly specified arguments for the "kube-watch" make sure the
following:

* the "kubectl" binary is available in the container (either mounted from the
  node or baked into the next layer image)
* running pod has enough permissions to watch the target object (see the Role
  in the [Fruits Example Manifest])
* handler executable is available in the container.

Some notes about arguments:

* if Namespace is omitted the current one will be used
* a Name should always be specified, but if empty (""), all the objects of
  specified type will be watched within a Namespace
* a label can be specified to watch specific group of objects within
  a Namespace.

Several not connected targets can be watched by running an accordingly
configured container per target.

### Watching Files

As you might noticed in the [Your Own Solution] section, the "usage" output
mentions "file" as a target along with the "object" one. In this case you can
specify a file path to watch. For that you need neither "kubectl" binary nor any
roles for Kubernetes objects watching permission.

Currently this feature works with mounted files only.

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
[Fruits Example Manifest]: manifests/kube-watch-fruits.yaml
[Your Own Solution]: #your-own-solution

<!-- Badges -->

[Apache 2.0]: https://opensource.org/licenses/Apache-2.0
[Apache 2.0 Badge]: https://img.shields.io/badge/License-Apache%202.0-yellowgreen.svg?style=flat-square
[GitHub Releases]: https://github.com/travelping/kube-watch/releases
[GitHub Release Badge]: https://img.shields.io/github/release/travelping/kube-watch/all.svg?style=flat-square
