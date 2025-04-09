# Contributing to SecuriWatch

Thank you for your interest in contributing to SecuriWatch! This document provides guidelines and instructions for contributing.

## Ways to Contribute

- Reporting bugs and issues
- Suggesting new features or improvements
- Improving documentation
- Submitting code changes and enhancements
- Sharing your experience with others

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/securiwatch.git`
3. Create a new branch: `git checkout -b feature/your-feature-name` or `fix/issue-description`
4. Make your changes
5. Test your changes thoroughly
6. Commit your changes with clear, descriptive messages
7. Push to your branch: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Environment

1. Set up a local development environment:
   ```bash
   # Clone the repository
   git clone https://github.com/YOUR-USERNAME/securiwatch.git
   cd securiwatch
   
   # Start the stack
   docker-compose up -d
   ```

2. Make your changes to the codebase

3. Test your changes:
   ```bash
   # Run the health check
   ./scripts/healthcheck.sh
   
   # Check logs for errors
   docker-compose logs -f
   ```

## Pull Request Guidelines

- Keep PRs focused on a single feature or bug fix
- Include a clear description of the changes
- Reference any related issues (e.g., "Fixes #123")
- Update documentation if necessary
- Make sure all tests pass

## Code Style

- Follow existing code style and conventions
- Add comments for complex sections of code
- Keep functions and methods focused and small
- Use meaningful variable and function names

## Reporting Bugs

When reporting bugs, please include:

- A clear, descriptive title
- Steps to reproduce the issue
- Expected and actual results
- Screenshots if applicable
- System information (OS, Docker version, etc.)

## Feature Requests

When suggesting features, please include:

- A clear description of the feature
- The motivation behind the feature
- Potential implementation details (if you have ideas)
- Any alternatives you've considered

## Documentation

Documentation is crucial for a project like SecuriWatch. Please help keep it up-to-date and clear.

## Community Guidelines

- Be respectful and considerate of others
- Provide constructive feedback
- Help others when possible
- Follow the code of conduct

Thank you for contributing to SecuriWatch! 