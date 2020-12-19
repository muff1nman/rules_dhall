let Prelude =
      env:DHALLBAZEL_prelude sha256:21754b84b493b98682e73f64d9d57b18e1ca36a118b81b33d0a243de8455814b

let map = Prelude.List.map

let kubernetes =
      env:DHALLBAZEL_k8s sha256:d4dc6b344408680ff1e30833881145ee79a9061758ed48dba3a9255d10cba9d4

let Service = { name : Text, host : Text, version : Text }

let services = [ { name = "foo", host = "foo.example.com", version = "2.3" } ]

let makeTLS
    : Service → kubernetes.IngressTLS.Type
    = λ(service : Service) →
        { hosts = Some [ service.host ]
        , secretName = Some "${service.name}-certificate"
        }

let makeRule
    : Service → kubernetes.IngressRule.Type
    = λ(service : Service) →
        { host = Some service.host
        , http = Some
          { paths =
            [ { backend =
                { serviceName = service.name
                , servicePort = kubernetes.IntOrString.Int 80
                }
              , path = None Text
              }
            ]
          }
        }

let mkIngress
    : List Service → kubernetes.Ingress.Type
    = λ(inputServices : List Service) →
        let annotations =
              toMap
                { `kubernetes.io/ingress.class` = "nginx"
                , `kubernetes.io/ingress.allow-http` = "false"
                }

        let defaultService =
              { name = "default"
              , host = "default.example.com"
              , version = " 1.0"
              }

        let ingressServices = inputServices # [ defaultService ]

        let spec =
              kubernetes.IngressSpec::{
              , tls = Some
                  ( map
                      Service
                      kubernetes.IngressTLS.Type
                      makeTLS
                      ingressServices
                  )
              , rules = Some
                  ( map
                      Service
                      kubernetes.IngressRule.Type
                      makeRule
                      ingressServices
                  )
              }

        in  kubernetes.Ingress::{
            , metadata = kubernetes.ObjectMeta::{
              , name = Some "nginx"
              , annotations = Some annotations
              }
            , spec = Some spec
            }

in  mkIngress services
