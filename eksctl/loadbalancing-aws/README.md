### AWS Load Balancer Comparison for EKS

| Feature                            | **Classic LB (CLB)**          | **Network LB (NLB)**                                         | **Application LB (ALB)**                   |
| ---------------------------------- | ----------------------------- | ------------------------------------------------------------ | ------------------------------------------ |
| **OSI Layer**                      | L4/L7                         | L4 (TCP/UDP)                                                 | L7 (HTTP/HTTPS)                            |
| **K8s Integration**                | `Service` type `LoadBalancer` | `Service` with annotation: <br>`aws-load-balancer-type: nlb` | `Ingress` via AWS Load Balancer Controller |
| **Path/Host Routing**              | ❌                             | ❌                                                            | ✅                                          |
| **SSL Termination**                | ✅ (via annotation)            | ✅ (with annotation)                                          | ✅ (native support with ACM)                |
| **WebSocket/gRPC Support**         | ❌                             | ✅                                                            | ✅                                          |
| **Static IP / Elastic IP Support** | ❌                             | ✅                                                            | ❌                                          |
| **HTTP/2 Support**                 | ❌                             | ❌                                                            | ✅                                          |
| **Health Checks**                  | Basic                         | Fast, TCP/HTTP                                               | Advanced (L7)                              |
| **Best for**                       | Legacy apps                   | High-performance TCP/UDP                                     | Modern HTTP apps (Ingress)                 |

---

### Notes

* Use **ALB** for modern web apps needing routing, TLS, and WAF.
* Use **NLB** for high-performance or internal TCP/UDP services.
* Avoid **CLB** for new projects unless required by legacy constraints.
