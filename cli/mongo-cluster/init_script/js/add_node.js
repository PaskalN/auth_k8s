function add_node(service_name, namespace, port) {

    const hostname = os.hostname;

    try {
        const host = `${hostname}.${service_name}.${namespace}.svc.cluster.local:${port}`        
        rs.add(host)
        print_green(`Node added: ${host}`)

        return 'success';
    } catch (err) {
        if (err.codeName === 'NewReplicaSetConfigurationIncompatible') {
            print_red('The node is already part of the set.')
            return 'exists';
        } else {
            print_red(`${JSON.stringify(err)}`)

            print_red('Retring in 10 sec')
            return 'error';
        }
    }
}
