# 参与贡献

欢迎提 Issue 和 Pull Request。

- **报告问题**：先运行 `/Applications/Standuppp.app/Contents/MacOS/standuppp --doctor`，把输出贴进 Issue。它只打印本机能看到的信息，不会发送任何东西。
- **改代码**：在 `app/` 目录下运行 `make test` 和 `make verify`，两者都通过再提交。
- **加一段搞笑提醒**：在 `app/Sources/StandupppCore/Sound/ReminderSkit.swift` 里加一个 case，写好开场音效、台词（中英文）和收尾音效，并补上测试。
- **安全问题**：请通过 GitHub 的 Security → Report a vulnerability 私下报告，不要公开发 Issue。

提交的代码遵循 [GPL-3.0](LICENSE)。
