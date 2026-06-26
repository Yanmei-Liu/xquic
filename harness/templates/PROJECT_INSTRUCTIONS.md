# XQUIC

XQUIC is a QUIC and HTTP/3 protocol library implemented in C, developed by Alibaba. It provides a high-performance, cross-platform implementation of the IETF QUIC transport protocol and the HTTP/3 application protocol.

## Project Structure

Each `src/` module and `tests/` has its own module-level instruction file with module-specific conventions, data structures, and pitfalls.

```
xquic/
├── src/
│   ├── transport/                # QUIC transport: conn, engine, stream, packet, send_ctl, cid, fec, datagram
│   ├── http3/                    # HTTP/3 + QPACK: h3_conn, h3_stream, h3_request, frame/, qpack/
│   ├── tls/                      # TLS 1.3: boringssl/ & babassl/ backends, crypto, hkdf
│   ├── congestion_control/       # BBR/BBR2/CUBIC/Reno/Copa, rate sampling, window filter
│   └── common/                   # Shared utils: log, memory pool, str, utils/
├── include/xquic/                # Public API: xquic.h, xqc_http3.h, xqc_errno.h, xquic_typedef.h
├── tests/                        # CUnit unit tests (unittest/) + integration client/server
├── demo/                         # HQ demo client/server
├── mini/                         # Minimal client/server examples
├── moq/                          # Media over QUIC (MoQ) transport, demo, tests
├── third_party/boringssl/        # BoringSSL source
├── cmake/                        # CMake modules (FindCUnit, FindSSL, etc.)
├── scripts/                      # Build and test scripts
├── docs_ai/                      # Dev reference docs (see Reference Documents below)
├── harness/                      # Agent skills and commands (platform-agnostic source)
├── CMakeLists.txt                # Root build configuration
└── xqc_configure.h.in           # Configure header template
```

## Task Routing

| Task Type | Examples | Required Entry Point |
|-----------|----------|----------------------|
| **Code change** | "Add feature X", "Refactor Y" | `docs_ai/dev_pipeline.md` |
| **Bug fix** | "Fix bug in Y", "Unit test X fails" | `docs_ai/bugfix_pipeline.md` |
| **Test / Build** | "Run tests", "Verify X works" | `docs_ai/validation_guide.md` |
| **Query / Analysis** | "How does X work?" | Read code + `docs_ai/code_map.md` |

## Git Branch Policy

- **NEVER push directly to `main` or `master` branch on remote.**
- Development work on feature branches, merged via Pull Request.
- Use `gh pr create` to submit changes for review.

## Coding Guidelines

1. **Naming**: Use `snake_case` with `xqc_` prefix. Comments explain "why", not "what".
2. **Code-doc sync**: When modifying a module, update corresponding docs (see `docs_ai/auto_doc_lookup.md`). When changing public APIs, update `include/xquic/` header docs. When adding new files, update `docs_ai/codebase_index.md`.
3. **Documentation minimalism**: Follow `docs_ai/doc_style_guide.md`. Keep generated comments/docs short, source-backed, non-duplicative, and focused on durable constraints.
4. **Testing**: Non-trivial changes must include tests and pass before completion.
5. **Evidence-based reasoning**: Read the relevant code path before claiming behavior or applying a fix.
6. **Post-modification verification**: After every change, re-read the modified path and verify consistency.
7. **AI knowledge-base upkeep**: Update `docs_ai/code_map.md`, `change_map.md`, `behavior_specs.md`, `decision_records.md` when relevant.

## Reference Documents

| Topic | Path |
|-------|------|
| System architecture | `docs_ai/architecture/overview.md` |
| Module dependencies | `docs_ai/architecture/module_dependency.md` |
| Build guide | `docs_ai/build/build_guide.md` |
| Test guide | `docs_ai/testing/test_guide.md` |
| Documentation style | `docs_ai/doc_style_guide.md` |
| Codebase file index | `docs_ai/codebase_index.md` |
| Source-to-doc mapping | `docs_ai/auto_doc_lookup.md` |
| Development pipeline | `docs_ai/dev_pipeline.md` |
| Bug fix pipeline | `docs_ai/bugfix_pipeline.md` |
| Validation guide | `docs_ai/validation_guide.md` |
| Code map | `docs_ai/code_map.md` |
| Change map | `docs_ai/change_map.md` |
| Behavior specs | `docs_ai/behavior_specs.md` |
| Decision records | `docs_ai/decision_records.md` |

## Build Dependencies

See `docs_ai/build/build_guide.md` for full build instructions and platform-specific notes.
