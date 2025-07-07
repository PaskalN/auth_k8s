function init(cluster_id, replicas, pod_name, service_name, namespace, port, user, pass) {

    try {
        const members = Array(parseInt(replicas)).fill(null).map((_, index) => {
            return {
                _id: index,
                host: `${pod_name}-${index}.${service_name}.${namespace}.svc.cluster.local:${port}`
            }
        })

        print_green(`MongoDB Cluster Members: ${JSON.stringify(members)}`)

        let success = false;
        while (!success) {
            try {
                rs.initiate({
                    _id: cluster_id,
                    members: members
                });
                print_green(`Replica set initiated successfully`);

                while (!db.isMaster().ismaster) {
                    print_yellow('MongoDB Cluster: Waiting for primary election...')
                    sleep(2000);
                }

                adminDB = db.getSiblingDB('admin');
                adminDB.createUser({
                    user: user,
                    pwd: pass,
                    roles: [{ role: 'root', db: 'admin' }]
                });

                print_green('MongoDB Admin user created!')

                success = true;

            } catch (e) {
                if (e.codeName === 'AlreadyInitialized' || e.codeName === 'Unauthorized') {
                    print_yellow(`MONGODB WARNING: ${e.codeName || e.message}`)
                    success = true;
                } else {
                    print_red(`MONGODB ERROR: ${e.codeName || e.message}`)
                }

                sleep(3500);
            }
        }       
    } catch (e) {
        if (e.codeName === 'AlreadyInitialized' || e.codeName === 'Unauthorized') {
            print_yellow(`MONGODB WARNING: ${e.codeName || e.message}`)
        } else {
            print_red(`MONGODB ERROR: ${e.codeName || e.message}`)
        }
    }
}
