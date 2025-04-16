#!/bin/bash
git config core.hooksPath .githooks
echo "Git hooks have been set up successfully!"
echo "The pre-commit hook will automatically update README.md when Piece.pm changes."
echo "Note: You need to have Pod::Markdown installed (cpanm Pod::Markdown)."
