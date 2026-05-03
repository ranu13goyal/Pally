# Project Workflows

- **Automatic Versioning:** After every successful build/verification of changes, the latest code should be committed and pushed to GitHub to maintain a continuous working history.
- **API Key Safety:** Never commit `iPal/Keys.plist`. Ensure it remains in `.gitignore`.
- **LLM Provider:** Use Groq (`llama-3.3-70b-versatile`) as the primary LLM provider.
