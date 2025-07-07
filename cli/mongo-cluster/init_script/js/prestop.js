function removeFromCluster(pod_dns) {
    try {
        rs.remove(pod_dns)
        print_green(`Node removed: ${pod_dns}`)

        cfg = rs.conf();
        cfg.version++
        rs.reconfig(cfg, {force: true});

        print_green(`Reconfiguring!`)

        return 'success';
    } catch (err) {
        print_red(`JSON.stringify(err)`)
        return 'error';                    
    }
}