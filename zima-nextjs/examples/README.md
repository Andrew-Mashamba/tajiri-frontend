# Zima Looper - Example Configurations

This directory contains example configuration files for different use cases. Copy one of these files to `../config.yaml` or specify it when running Zima.

## Available Configurations

### 1. `config-strict.yaml` - Production Quality Enforcement

**Use when:**
- Building production-ready applications
- Quality is more important than speed
- You need comprehensive test coverage
- You want an audit trail of all changes

**Features:**
- ✅ All quality gates required
- ✅ Tests must pass before story completion
- ✅ Syntax validation required
- ✅ Composer validation required
- ✅ Environment file validation
- ✅ Automatic rollback on failures
- ✅ Detailed logging for audit
- ✅ 4 parallel workers
- ⏱️ Longer timeouts (10-30 minutes)

**Best for:** Enterprise projects, client work, production deployments

**Usage:**
```bash
cp examples/config-strict.yaml config.yaml
./zima.sh execute --project my-project
```

---

### 2. `config-lenient.yaml` - Rapid Development

**Use when:**
- Iterating quickly on prototypes
- Tests are not yet written
- Speed is more important than quality
- Exploring new features

**Features:**
- ⚡ Tests optional (won't block on failures)
- ⚡ Minimal quality requirements
- ⚡ Faster timeouts (5-15 minutes)
- ⚡ No rollback on failures (keep changes)
- ⚡ Less verbose logging
- ⚡ 4 parallel workers
- ⚡ Only 2 retry attempts

**Best for:** Prototypes, MVPs, hackathons, early development

**Usage:**
```bash
cp examples/config-lenient.yaml config.yaml
./zima.sh execute --project my-prototype
```

---

### 3. `config-single-worker.yaml` - Debugging & Troubleshooting

**Use when:**
- Debugging story execution issues
- Need sequential execution for clarity
- Tracking down race conditions
- Learning how Zima works

**Features:**
- 🐛 Single worker (sequential execution)
- 🐛 DEBUG log level (verbose output)
- 🐛 Detailed logging for every operation
- 🐛 More checkpoints (15 per story)
- 🐛 Longer timeouts for investigation
- 🐛 Direct commits (no branches)
- 🐛 Balanced quality gates

**Best for:** Debugging, learning, investigating issues

**Usage:**
```bash
cp examples/config-single-worker.yaml config.yaml
./zima.sh execute --project my-project
```

---

### 4. `config-fast.yaml` - Maximum Speed

**Use when:**
- Running quick experiments
- Building throwaway prototypes
- Testing PRD generation
- Speed is the only priority

**Features:**
- 🚀 Minimal quality checks (syntax only)
- 🚀 No tests required
- 🚀 Short timeouts (3-10 minutes)
- 🚀 Only 1 retry attempt
- 🚀 No dashboard overhead
- 🚀 ERROR-level logging only
- 🚀 No rollback on failures
- 🚀 4 parallel workers

**Best for:** Quick experiments, throwaway code, speed tests

**Usage:**
```bash
cp examples/config-fast.yaml config.yaml
./zima.sh execute --project quick-test
```

---

## Configuration Comparison

| Feature | Strict | Lenient | Single Worker | Fast |
|---------|--------|---------|---------------|------|
| **Workers** | 4 | 4 | 1 | 4 |
| **Tests Required** | ✅ Yes | ❌ No | ✅ Yes | ❌ No |
| **Quality Gates** | All | Minimal | Balanced | Syntax Only |
| **Rollback on Fail** | ✅ Yes | ❌ No | ✅ Yes | ❌ No |
| **Retry Attempts** | 3 | 2 | 3 | 1 |
| **Default Timeout** | 10 min | 5 min | 10 min | 3 min |
| **Log Level** | INFO | WARNING | DEBUG | ERROR |
| **Dashboard** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| **Claude Fix** | ✅ Yes | ✅ Yes | ✅ Yes | ❌ No |
| **Best For** | Production | Prototypes | Debugging | Speed |

---

## Customizing Configurations

You can create your own configuration by copying one of these files and modifying it:

```bash
# Start with lenient config
cp examples/config-lenient.yaml config.yaml

# Edit to customize
vim config.yaml
```

### Key Settings to Adjust

#### Worker Count
```yaml
workers:
  count: 2  # Reduce for slower machines, increase for faster
```

#### Timeout Tuning
```yaml
claude:
  default_timeout_seconds: 300  # Adjust based on story complexity
```

#### Quality Requirements
```yaml
quality:
  require_passing_tests: true   # Set to false to allow test failures
  allow_no_tests: false          # Set to true if tests not written yet
```

#### Retry Strategy
```yaml
retry:
  max_attempts: 3               # Number of retries before giving up
  enable_claude_fix: true       # Use Claude to analyze and fix errors
```

---

## Switching Configurations

### Option 1: Copy to config.yaml
```bash
cp examples/config-strict.yaml config.yaml
./zima.sh execute --project my-project
```

### Option 2: Specify config path (if supported)
```bash
./zima.sh execute --project my-project --config examples/config-strict.yaml
```

### Option 3: Environment variable (if supported)
```bash
export ZIMA_CONFIG=examples/config-strict.yaml
./zima.sh execute --project my-project
```

---

## Creating Project-Specific Configs

For complex projects, you can create project-specific configurations:

```bash
# Create project config
cp examples/config-strict.yaml my-project/zima-config.yaml

# Customize for project
vim my-project/zima-config.yaml

# Use it (if path specification is supported)
./zima.sh execute --project my-project --config my-project/zima-config.yaml
```

---

## Troubleshooting Configurations

### Tests keep timing out
**Solution:** Increase `test_timeout_seconds` in quality section
```yaml
quality:
  test_timeout_seconds: 1200  # 20 minutes
```

### Stories failing due to quality gates
**Solution:** Use `config-lenient.yaml` or adjust requirements
```yaml
quality:
  require_passing_tests: false
  allow_no_tests: true
```

### Too slow execution
**Solution:** Use `config-fast.yaml` or reduce workers
```yaml
workers:
  count: 2  # Fewer workers = less resource contention
```

### Need more visibility
**Solution:** Use `config-single-worker.yaml` with DEBUG logging
```yaml
monitoring:
  log_level: "DEBUG"
  detailed_logging: true
```

---

## Best Practices

1. **Start with lenient** - Use `config-lenient.yaml` during initial development
2. **Switch to strict** - Move to `config-strict.yaml` as project matures
3. **Debug with single worker** - Use `config-single-worker.yaml` when investigating issues
4. **Version control your config** - Commit your customized config.yaml to git
5. **Document changes** - Add comments explaining why you changed settings

---

## Support

For more information on configuration options, see the main [README.md](../README.md) or run:

```bash
./zima.sh help
```
