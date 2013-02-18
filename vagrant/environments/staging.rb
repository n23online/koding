name "staging"
description "The staging environment"

cookbook_versions({
    "local_users"   => "0.1.3",
    "apt"           => "1.7.0",
    "base_packages" => "0.1.0",
    "erlang"        => "1.1.2",
    "golang"        => "0.1.0",
    "golang"        => "0.1.0",
    "mongodb"       => "0.1.0",
    "nginx"         => "1.1.2",
    "nodejs"        => "0.1.0",
    "ohai"          => "1.1.6",
    "rabbitmq"      => "1.7.0",
    "users"         => "1.3.0",
    "yum"           => "2.0.6",
    "kd_deploy"     => "0.1.1",
    "ntp"           => "1.3.2",
    "lvm"           => "0.8.4"
})


default_attributes({ 
                     "launch" => {
                                 "config" => "stage",
                     },
                     "kd_deploy" => {
                                "git_branch" => "master_STAGE",
                                "revision_tag" => "HEAD",
                                "release_action" => :deploy,
                                "deploy_dir" => '/opt/koding',
                     },
                    "nginx" => {
                                "worker_processes" => "1",
                                "backend_ports" => [3020],
                                "server_name" => "www.stage.aws.koding.com",
                                "rc_server_name" => "localhost",
                                "maintenance_page" => "maintenance.html",
                                "static_files" => "/opt/koding/current/client"
                     },
                     :rabbitmq => {
                                :admin_password => "dslkdscmckfjf55",
                                :user_password => "djfjfhgh4455__5"
                     },
                    "mongodb" => {
                                "source" => "db-m0.stage.aws.koding.com",
                     } 
})
