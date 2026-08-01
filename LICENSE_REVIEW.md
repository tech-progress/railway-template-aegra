# License review

Aegra `0.9.24`, including `aegra-api` and `aegra-cli`, is Apache-2.0. The template-authored container, authentication hook, and example graph are released under the same permissive boundary; PostgreSQL, pgvector, Redis, Python, and transitive Python dependencies retain their respective upstream licenses.

The template installs official PyPI artifacts from a complete hash-locked dependency file. It does not redistribute a modified Aegra binary or include proprietary model weights, hosted-service credentials, or upstream example assets.
