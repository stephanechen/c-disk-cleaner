# 用户自定义软件配置

> 将本机特有的软件路径填入此文件。扫描引擎会读取此配置，自动识别并标注你的软件。
> 
> 使用时复制此模板，填写后保存为 `custom-config.yaml` 或直接告知 AI 你的软件列表。

---

## 模板

```yaml
# 我的自定义软件列表
# 路径格式：C:\Users\<用户名>\ 下的相对路径

custom_software:
  # 添加你的专属软件
  - name: "行业专用软件A"
    paths:
      - "AppData\\Roaming\\MyIndustryApp"
      - "Documents\\MyIndustryApp Projects"
    safety: caution          # safe / caution / system
    action: migrate           # clean / clean-cache / migrate / manual / disk-cleanup / powercfg
    note: "行业软件数据，建议迁移到D盘"
    category: "行业软件"

  - name: "公司内部工具B"
    paths:
      - "AppData\\Local\\CompanyToolB"
    safety: safe
    action: clean
    note: "内部工具缓存，定期清理"
    category: "内部工具"

  - name: "某游戏"
    paths:
      - "Documents\\My Games\\SomeGame"
    safety: caution
    action: migrate
    note: "游戏存档，建议迁移"
    category: "游戏"
```

---

## 字段说明

| 字段 | 必填 | 可选值 |
|------|------|--------|
| `name` | 是 | 软件名称（任意） |
| `paths` | 是 | 数据路径列表（相对于用户目录） |
| `safety` | 是 | `safe`（安全）/ `caution`（需确认）/ `system`（系统） |
| `action` | 是 | `clean`（清理） / `clean-cache`（清缓存） / `migrate`（迁移） / `manual`（手动） / `disk-cleanup`（磁盘清理） / `powercfg`（电源管理） |
| `note` | 否 | 备注说明 |
| `category` | 否 | 分类名称（任意） |

---

## 如何找到你的软件数据路径

大多数软件把数据放在：

1. `C:\Users\<用户名>\AppData\Local\` — 应用本地数据（缓存为主）
2. `C:\Users\<用户名>\AppData\Roaming\` — 应用漫游数据（配置为主）
3. `C:\Users\<用户名>\AppData\LocalLow\` — 低权限应用数据（部分游戏/输入法）
4. `C:\Users\<用户名>\Documents\` — 用户文档/游戏存档
5. `C:\ProgramData\` — 全局应用数据

推荐用 [WinDirStat](https://windirstat.net/) 或 [WizTree](https://diskanalyzer.com/) 可视化定位大目录。
