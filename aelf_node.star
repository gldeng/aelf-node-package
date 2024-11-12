SERVICE_NAME = "aelf-node"
IMAGE_NAME = "gldeng/aelf-test-node:sha1514159"
APPSETTINGS_TEMPLATE_FILE = "/static_files/appsettings.json.template"
APPSETTINGS_AELFINDER_FEEDER_TEMPLATE_FILE = "/static_files/appsettings.aefinder-feeder.json.template"


def run(
    plan,
    with_aefinder_feeder=False,
    redis_url=None,
    rabbitmq_node_hostname=None,
    rabbitmq_node_port=None,
    port_number=8000,
    port_is_public=False
):
    if with_aefinder_feeder and not (redis_url and rabbitmq_node_hostname and rabbitmq_node_port):
        fail("redis_url, rabbitmq_node_hostname and rabbitmq_node_port are required when with_aefinder_feeder is true")

    common_content = read_file(APPSETTINGS_TEMPLATE_FILE)
    common_data = {
        "Host": SERVICE_NAME,
        "Port": port_number,
    }
    if with_aefinder_feeder:
        template_data = common_data | {
            "RedisHostPort": redis_url.split("/")[-1],
            "RabbitMqHost": rabbitmq_node_hostname,
            "RabbitMqPort": rabbitmq_node_port,
            "PluginSourcesFolder": "/app/plugins",
        }
        aefinder_feeder_content = read_file(APPSETTINGS_AELFINDER_FEEDER_TEMPLATE_FILE)
        common_parsed = json.decode(common_content)
        aefinder_feeder_parsed = json.decode(aefinder_feeder_content)
        merged = common_parsed|aefinder_feeder_parsed
        template_content = json.indent(json.encode(merged), prefix="", indent="  ") if with_aefinder_feeder else common_content
    else:
        template_data = common_data
        template_content = common_content

    artifact_name = plan.render_templates(
        config = {
            "appsettings.json": struct(
                template=template_content,
                data=template_data,
            ),
        },
    )

    plugins_artifact_name = plan.upload_files(
        src = "/static_files/plugins"
    )

    public_ports = {}
    if port_is_public:
        public_ports["http"] = PortSpec(number=port_number)

    plan.add_service(SERVICE_NAME, ServiceConfig(
        image=IMAGE_NAME,
        ports={
            "http": PortSpec(number=port_number),
            # "p2p": PortSpec(number=6801),
            # "grpc": PortSpec(number=5001),
        },
        public_ports=public_ports,
        files={
            "/app/config": artifact_name,
            "/app/plugins": plugins_artifact_name,
        },
        entrypoint = [
            "/bin/sh", 
            "-c", 
            "cp /app/config/* /app/ && cat /app/appsettings.json && dotnet AElf.Launcher.dll"
        ],
    ))
    return {
        "aelf_node_url": "http://{host}:{port}".format(host=SERVICE_NAME, port=port_number)
    }