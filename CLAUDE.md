# CLAUDE.md - AI Assistant Guide for docker-tricks

## Repository Overview

This is a **Docker containerization experiments and utilities** repository focused on:
- Docker containerization techniques and patterns
- CI/CD system containerization (Buildbot-based)
- AWS ECS prototyping and testing with LocalStack
- Docker orchestration tools and utilities

**Primary Goal**: Explore containerization patterns to smoothly transition from "Works on my machine" to "Works wherever I want it to work".

## Repository Structure

```
docker-tricks/
├── bbot-base/              # Buildbot base container
│   ├── Dockerfile          # CentOS 7.5-based image with Python virtualenv
│   ├── python-dependencies/# Offline Python packages for Buildbot
│   └── test.sh            # Test script for the container
├── ecs-prototype/          # AWS ECS local development environment
│   ├── docker-compose.yml  # Orchestrates LocalStack, sample app, Jenkins
│   ├── sample-app/        # Flask app demonstrating ECS patterns
│   ├── localstack-init/   # AWS resource initialization scripts
│   ├── jenkins/           # CI/CD pipeline examples
│   └── scripts/           # Helper scripts (start, stop, logs, reset)
├── quickstart/            # Simple nginx Docker example
│   ├── Dockerfile         # Ubuntu + nginx
│   └── index.html         # Sample web page
├── nifty/                 # Multi-stage build example
│   └── Dockerfile         # Demonstrates intermediate build stages
├── d.run                  # Container orchestration tool (Python)
├── d.stop                 # Symlink to d.run (stops containers)
├── cleanup.sh             # Cleanup exited containers and dangling images
├── md.py                  # Markdown to HTML converter
├── hack.yaml              # Example container configuration
└── requirements.txt       # Python dependencies (Jinja2, Markdown)
```

## Key Components

### 1. Buildbot Base Container (`bbot-base/`)

**Purpose**: Production-ready Buildbot environment with offline Python dependencies.

**Key Features**:
- Multi-stage Docker build pattern
- CentOS 7.5.1804 base
- Python virtualenv at `/python-sandbox`
- Comprehensive dev tools (gcc, git, vim, etc.)
- Offline pip installation from vendored packages
- MySQL, OpenSSH, and Buildbot 0.8.9

**Build Command**: `docker build -t bbot_base .`

**Important Notes**:
- Stage 1 creates virtualenv with dependencies
- Stage 2 copies only virtualenv, not source packages (reduces image size)
- Uses `--no-index --find-links` for offline pip installation

### 2. ECS Prototype Environment (`ecs-prototype/`)

**Purpose**: Local development environment mimicking AWS ECS with LocalStack.

**Services Provided**:
- **LocalStack**: Emulates ECS, ECR, ALB, SSM, Secrets Manager, IAM, CloudWatch
- **Sample App**: Flask application demonstrating AWS SDK usage
- **Jenkins**: CI/CD pipeline testing
- **AWS CLI**: Pre-configured container for manual testing

**Key Endpoints**:
- LocalStack: `http://localhost:4566`
- Sample App: `http://localhost:8080`
- Jenkins: `http://localhost:8081`

**Common Operations**:
```bash
cd ecs-prototype
docker-compose up -d                    # Start environment
docker-compose ps                       # Check status
docker-compose logs -f localstack       # View logs
docker-compose exec aws-cli sh          # Enter AWS CLI container
docker-compose down -v                  # Full reset
```

**Testing Patterns**:
- Use AWS CLI with `--endpoint-url=http://localstack:4566`
- All AWS credentials use `test/test` (LocalStack default)
- Region: `us-east-1`

**Important Notes**:
- LocalStack's ECS is simplified (not full Fargate)
- Containers run in Docker Compose, not true ECS tasks
- Good for testing deployment scripts before production
- See `ecs-prototype/README.md` for comprehensive documentation

### 3. Container Orchestration Tool (`d.run`)

**Purpose**: YAML-driven Docker container management (early Ansible-style approach).

**Usage**:
```bash
./d.run -y hack.yaml           # Start containers
./d.stop -y hack.yaml          # Stop containers (via symlink)
```

**Features**:
- YAML specification of containers, ports, and mounts
- Stores container IDs in `.container_ids.yaml`
- Maps ports as `container_port: host_port`
- Maps volumes as `container_path: host_path`

**Configuration Format** (`hack.yaml`):
```yaml
container_name:
    image: "ubuntu:latest"
    mounts:
        /work: work
    ports:
        80: 8080
```

### 4. Utility Scripts

**`cleanup.sh`**: Removes exited containers and dangling images
```bash
./cleanup.sh  # Clean up Docker artifacts
```

**`md.py`**: Converts Markdown to styled HTML
```bash
./md.py README.md -o output.html
```

## Development Workflows

### Docker Image Building

**Standard Pattern**:
```bash
cd <directory>
docker build -t <image_name> .
```

**Multi-stage Build Pattern** (see `nifty/Dockerfile`):
```dockerfile
FROM ubuntu as intermediate
# Build steps here
FROM ubuntu
COPY --from=intermediate /result /result
```

### Testing Docker Containers

1. **Build the image**
2. **Run interactively**: `docker run -it --rm <image_name> /bin/bash`
3. **Test specific functionality**
4. **Clean up**: Use `cleanup.sh` to remove test artifacts

### ECS Development Workflow

1. **Start environment**: `cd ecs-prototype && docker-compose up -d`
2. **Wait for health checks**: Check `docker-compose ps`
3. **Test AWS resources**: Use aws-cli container or sample app
4. **Modify resources**: Edit `localstack-init/01-setup-resources.sh`
5. **Restart**: `docker-compose restart localstack`
6. **Test deployment scripts**: Run through Jenkins or manually
7. **Iterate**: Make changes, test, repeat
8. **Clean up**: `docker-compose down -v`

### Git Workflow

**Branch Naming**: Use feature branches with `claude/` prefix for AI-assisted work
- Format: `claude/<descriptive-name>-<session-id>`
- Example: `claude/setup-ecs-docker-compose-011CUTEjEiEkANMf9RFf77fr`

**Commit Practices**:
- Descriptive commit messages
- Security-related commits use "Bump X from Y to Z" format
- Merge commits for PR integration

**Recent Activity**: Major work includes ECS prototype setup and dependency security updates

## Docker Conventions

### Image Naming
- Use descriptive tags: `bbot_base`, `quickstart`, `hack`
- Avoid `latest` in production contexts
- Tag with version numbers when appropriate

### Port Mapping
- Format: `host_port:container_port`
- Bind to `127.0.0.1` for localhost-only access
- Document exposed ports in Dockerfile via `EXPOSE`

### Volume Mounts
- Use absolute paths for host directories
- Prefer named volumes for data persistence
- Document mount points in configuration files

### Networking
- Use Docker networks for service communication
- Name networks descriptively (e.g., `ecs-network`)
- Use service names for DNS resolution in compose

### Multi-stage Builds
- Use `as intermediate` for build stages
- Copy only necessary artifacts to final image
- Reduces image size significantly

## Key File Patterns

### Dockerfile Patterns

**Basic Service**:
```dockerfile
FROM ubuntu
RUN apt-get update && apt-get install -y <packages>
COPY files /destination
EXPOSE <port>
CMD ["service", "start"]
```

**Build + Runtime**:
```dockerfile
FROM base as builder
# Build dependencies and compile
FROM base
COPY --from=builder /artifacts /app
# Only runtime dependencies
```

### Docker Compose Patterns

**Service Dependencies**:
```yaml
depends_on:
  service_name:
    condition: service_healthy
```

**Health Checks**:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:port/health"]
  interval: 10s
  timeout: 5s
  retries: 5
```

**Environment Variables**:
```yaml
environment:
  - VAR_NAME=value
  - AWS_ENDPOINT_URL=http://localstack:4566
```

## Testing Conventions

### LocalStack Testing
1. Always check health endpoint first: `curl http://localhost:4566/_localstack/health`
2. Use `--endpoint-url` for all AWS CLI commands
3. Use test credentials: `test/test`
4. Check initialization logs if resources missing

### Container Testing
1. Build locally first
2. Run with `--rm` for automatic cleanup
3. Use `-it` for interactive testing
4. Check logs: `docker logs <container_id>`

### Integration Testing
1. Use docker-compose for multi-service tests
2. Wait for health checks before testing
3. Test service-to-service communication
4. Clean up with `docker-compose down -v`

## AI Assistant Guidelines

### When Making Changes

1. **Read First**: Always read existing files before modifying
2. **Understand Context**: Check related configuration files
3. **Test Locally**: Ensure Docker builds/runs succeed
4. **Preserve Patterns**: Follow existing conventions
5. **Document Changes**: Update relevant READMEs

### Docker-Specific Practices

1. **Use Multi-stage Builds**: When dependencies differ between build and runtime
2. **Minimize Layers**: Combine RUN commands with `&&`
3. **Clean Cache**: Add `apt-get clean` after installs
4. **Pin Versions**: Specify exact versions for reproducibility
5. **Security**: Keep base images and dependencies updated

### ECS Prototype Work

1. **LocalStack Limitations**: Not all AWS features work
2. **Service Health**: Always verify with health checks
3. **Resource Initialization**: Check `localstack-init/` scripts
4. **Networking**: Use service names, not localhost
5. **Logs**: Monitor multiple services simultaneously

### Code Organization

1. **One Purpose Per Directory**: Each subdirectory has a specific focus
2. **Self-Contained Examples**: Each directory should work independently
3. **Documentation**: Add README for complex setups
4. **Scripts**: Make helper scripts executable (`chmod +x`)

### Security Considerations

1. **Dependency Updates**: Check for security advisories
2. **Secrets**: Never commit secrets (use .gitignore)
3. **LocalStack**: Only for local development, not production
4. **Base Images**: Use official images when possible
5. **Minimal Privileges**: Don't run as root unless necessary

### Common Pitfalls to Avoid

1. **Hardcoded Paths**: Use environment variables or configuration
2. **Localhost References**: Use service names in docker-compose
3. **Missing Health Checks**: Always implement for services
4. **Large Images**: Use .dockerignore and multi-stage builds
5. **Dangling Resources**: Clean up test containers and images

### Useful Commands Reference

```bash
# Container Management
docker ps -a                           # List all containers
docker rm -f $(docker ps -aq)         # Remove all containers
docker images                          # List images
docker rmi $(docker images -q)        # Remove all images

# Debugging
docker logs <container>                # View logs
docker exec -it <container> bash      # Enter container
docker inspect <container>             # Detailed info

# Cleanup
docker system prune -a                # Remove unused data
./cleanup.sh                          # Project cleanup script

# Docker Compose
docker-compose up -d                  # Start in background
docker-compose logs -f <service>      # Follow logs
docker-compose exec <service> sh      # Execute command
docker-compose down -v                # Stop and remove volumes
```

## Dependencies

### Python Dependencies
- **Jinja2** (2.11.3): Template engine for md.py
- **Markdown** (3.1.1): Markdown processing
- **MarkupSafe** (1.1.1): String escaping

### System Dependencies
- Docker Engine (recent version)
- Docker Compose v3.8+
- Python 3.x (for d.run and md.py)
- Bash (for shell scripts)

## Maintenance Notes

### Regular Tasks
1. **Update base images**: Periodically rebuild with latest bases
2. **Security updates**: Monitor and update dependencies
3. **Cleanup**: Run cleanup.sh to free disk space
4. **Documentation**: Keep READMEs current with changes

### Known Issues
- d.run tool is experimental (consider docker-compose instead)
- bbot-base uses older CentOS 7.5 (might need upgrade path)
- Some Python dependencies in bbot-base are outdated (but intentional for compatibility)

## Resources and References

### External Links
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [LocalStack Docs](https://docs.localstack.cloud/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Julia Evans (@b0rk) Container Resources](https://twitter.com/b0rk)

### Project Documentation
- Main README: `README.md`
- ECS Prototype: `ecs-prototype/README.md`
- Docker Runner: `d-runner.md`

## Quick Start for AI Assistants

When first working with this repository:

1. **Understand the Goal**: Review main README.md
2. **Identify Component**: Determine which subsystem needs work
3. **Read Local Docs**: Check subdirectory READMEs
4. **Test First**: Ensure environment works before changing
5. **Make Changes**: Follow established patterns
6. **Verify**: Build/run to confirm changes work
7. **Document**: Update relevant documentation
8. **Commit**: Use clear, descriptive messages

This repository values **experimentation**, **practical examples**, and **smooth containerization workflows**. When in doubt, favor simplicity and maintainability over complexity.
