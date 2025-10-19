# .bashrc 说明（简要）

此文件是 /home/lyra 的交互式 Bash 启动脚本，包含常规的环境、别名和若干自定义的 ROS2 工作空间管理辅助函数。下面是功能概览与使用示例。

## 全局设置 & 环境
- 启用历史记录优化（HISTCONTROL、histappend 等）。
- 终端颜色提示与 PS1 配置（支持 xterm 标题）。
- 启用 bash-completion（若系统有相关文件）。
- 启用目录颜色与常用 alias（ls、ll、la、l、grep 等）。
- 加载 ROS 环境：`source /opt/ros/humble/setup.bash`（文件中以 `fishros initialize` 注释标注）
- 加载 Rust cargo 环境：`. "$HOME/.cargo/env"`
- 导出 `ROS_ROOT="/opt/ros/humble"`

## 自定义实用函数
1. mkcd
- 用途：创建目录并进入
- 用法：`mkcd path/to/dir`

2. ROS2 工作空间管理（存储路径：`$HOME/.ros_workspaces`）
- rosws
  - 列举已保存工作空间并交互式切换到选中路径。
  - 切换后若存在 `install/setup.bash` 会自动 source。
  - 用法：`rosws`（按提示输入编号或回车取消）

- rosws-add
  - 将当前目录加入工作空间列表（若不存在则创建文件）。
  - 添加后会询问是否为该工作空间生成 `.clangd` 配置。
  - 用法：在工作空间根目录运行 `rosws-add`

- rosws-rm
  - 交互式删除列表中的某个工作空间。
  - 用法：`rosws-rm`

- rosws-clangd
  - 为当前目录（假定为 ROS2 工作空间）生成一个 `.clangd` 文件，包含常见 include 路径与 clangd 设置。
  - 若未检测到 `src` 目录，会提示是否继续生成。
  - 用法：`rosws-clangd`
  - 建议：生成后重启 VSCode/clangd 或运行 clangd 重启命令；如需编译数据库，运行：
    `colcon build --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`

- rosws-colcon-config
  - 快速创建 `.colcon/defaults.yaml`，使 `colcon build` 自动生成 compile_commands.json
  - 用法：在工作空间根目录运行 `rosws-colcon-config`

- 其它
  - alias `rosws-list`：显示保存的工作空间列表（或提示没有保存）

## 文件与常量
- 工作空间列表文件：`$HOME/.ros_workspaces`
- 默认 clangd 会包含：
  - `/opt/ros/humble/include`
  - `${workspaceFolder}/install/include`
  - `${workspaceFolder}/src`
  - `-std=c++17`
- `.bash_aliases` 若存在会被加载

## 常见操作示例
- 添加当前工作空间并生成 .clangd：
  - cd 到工作空间根目录，运行 `rosws-add`，按提示选择生成 `.clangd`
- 切换工作空间并 source install/setup.bash：
  - `rosws` → 输入对应编号
- 删除保存的工作空间：
  - `rosws-rm` → 输入编号

## 故障排查
- 未列出工作空间：检查 `$HOME/.ros_workspaces` 是否存在且非空
- 切换后找不到 `install/setup.bash`：确保已执行 colcon build 并安装到 `install/`
- clangd 未生效：重启编辑器或手动重启 clangd；确认 `.clangd` 内容正确

## 扩展建议
- 可把大量别名放到 `~/.bash_aliases`，便于管理。
- 若使用其他 ROS 发行版，修改 `source /opt/ros/humble/setup.bash` 与 `ROS_ROOT` 值。
- 若需要更多自动补全，可以安装并启用系统级 bash-completion。

----
生成于用户 home 目录的 .bashrc，供快速参考与使用说明。若需更详细的 README（示例截图、输出示例或自动化脚本），说明需要的内容即可生成。 
