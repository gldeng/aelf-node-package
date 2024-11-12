
aelf_node_module = import_module("/aelf-node.star")
infra_module = import_module("github.com/gldeng/aelf-infra-package/main.star")

def run(
    plan,
    with_aefinder_feeder=False
):
    infra_output = infra_module.run(plan, need_redis=with_aefinder_feeder, need_rabbitmq=with_aefinder_feeder)
    output = aelf_node_module.run(
        plan,
        with_aefinder_feeder,
        infra_output["redis_url"],
        infra_output["rabbitmq_node_hostname"],
        infra_output["rabbitmq_node_port"]
    )
    return infra_output | output
