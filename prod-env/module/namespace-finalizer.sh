#NAMESPACE="monitoring"
helm uninstall prometheus -n monitoring 2>&1 &
kubectl delete ns monitoring 2>&1 &
sleep 150
kubectl get namespaces
kubectl describe namespaces
kubectl get namespace monitoring -o json > ./monitoring.json
sed -i -e 's/"kubernetes"//' ./monitoring.json
kubectl replace --raw "/api/v1/namespaces/monitoring/finalize" -f ./monitoring.json
kubectl get namespaces
helm ls --namespace monitoring
