# Support

This template maintains the Railway topology, immutable image and package pins, authentication hook, bundled graph, and release verification. Aegra application behavior and Agent Protocol compatibility belong upstream at [aegra/aegra](https://github.com/aegra/aegra).

The release is a single-Aegra-instance baseline. PostgreSQL and Redis persist independently, and Aegra recovers leased jobs after process failure, but the template does not claim database high availability, multi-region operation, autoscaling, private-only ingress, or managed observability.
