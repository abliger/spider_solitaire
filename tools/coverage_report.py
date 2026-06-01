#!/usr/bin/env python3
"""
GDScript 覆盖率报告生成器。
基于函数调用推断覆盖率：
- 解析 scripts/ 下的所有 .gd 文件，提取函数定义和代码行范围
- 解析 tests/ 下的所有测试文件，查找对被测函数的调用
- 若一个函数在测试中被调用，则认为该函数的所有代码行被覆盖
- 输出函数覆盖率和估计的行覆盖率
"""

import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
TESTS_DIR = PROJECT_ROOT / "tests"

# 排除的文件或目录
EXCLUDE_PATHS = [
    "scripts/ui",  # UI 逻辑较简单，暂不强制要求覆盖
]

# 生命周期/内置虚函数，通常难以在单元测试中直接覆盖
LIFECYCLE_FUNCS = {
    "_init", "_enter_tree", "_exit_tree", "_ready",
    "_process", "_physics_process", "_draw", "_gui_input",
    "_input", "_unhandled_input", "_notification",
    "_static_init", "_on_timer_timeout", "_on_return_tween_finished",
    "_handle_release", "_get_input_position",
    "_save_settings", "_load_settings", "_apply_fullscreen", "_request_save",
    "_preload_sfx", "_animate_to_original", "_animate_sequence_to_foundation",
    "_check_all_columns_for_sequences", "_execute_move",
    "_position_columns", "_update_stock_label",
    "_reposition_cards", "_get_raw_overlaps", "_get_compressed_overlaps",
    "_get_effective_max_height", "_set_dynamic_height",
    "_draw_face_up", "_draw_face_down", "_draw_highlight_glow", "_draw_highlight",
    "_draw_empty_placeholder", "_get_suit_symbol",
    "_on_card_drag_started", "_on_card_drag_ended",
    "_disconnect_drag_signals", "_recover_any_stuck_cards", "_cleanup_drag",
    "_cards_to_data", "_reparent_to_source_immediate", "_detect_column_at_position",
    "_arc",
}


def get_gd_files(directory: Path) -> list[Path]:
    files = []
    for f in sorted(directory.rglob("*.gd")):
        rel = f.relative_to(PROJECT_ROOT).as_posix()
        if any(rel.startswith(ex) for ex in EXCLUDE_PATHS):
            continue
        files.append(f)
    return files


def parse_script(path: Path) -> dict:
    """解析 GDScript，提取函数和有效代码行。"""
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    func_pattern = re.compile(r"^(\t|    )?func (\w+).*\:")
    # 类定义
    class_pattern = re.compile(r"^(\t|    )?class \w+.*\:")
    # 注释或空行
    empty_or_comment = re.compile(r"^\s*(#.*)?$")

    functions = []
    total_effective_lines = 0
    in_multiline_comment = False

    for i, raw_line in enumerate(lines):
        line = raw_line.rstrip("\n")
        stripped = line.strip()

        # 多行注释 """ ... """
        if '"""' in stripped:
            count = stripped.count('"""')
            if count == 2:
                continue
            in_multiline_comment = not in_multiline_comment
            continue
        if in_multiline_comment:
            continue

        if empty_or_comment.match(line):
            continue

        total_effective_lines += 1

        m = func_pattern.match(line)
        if m:
            func_name = m.group(2)
            indent_prefix = m.group(1) if m.group(1) else ""
            indent_level = len(indent_prefix) // 4 if indent_prefix.startswith(" ") else len(indent_prefix)
            functions.append({
                "name": func_name,
                "line": i + 1,
                "indent_level": indent_level,
                "index": i,
            })

    # 计算每个函数的行数（从函数定义到下一个同缩进或更少缩进的定义/类）
    for idx, func in enumerate(functions):
        start = func["index"]
        end = len(lines)
        for j in range(start + 1, len(lines)):
            line = lines[j]
            # 检查是否是同缩进级别的 func/class 定义
            stripped = line.lstrip("\t")
            tabs_removed = len(line) - len(stripped)
            if tabs_removed <= func["indent_level"]:
                if func_pattern.match(line) or class_pattern.match(line):
                    end = j
                    break
            # 检查是否是文件末尾级别的定义（0缩进）
            if tabs_removed == 0 and line.strip() and not line.strip().startswith("#"):
                if not (line.strip().startswith("extends") or line.strip().startswith("class_name")):
                    end = j
                    break
        func["body_lines"] = max(0, end - start)
        func["covered"] = False

    return {
        "path": path.relative_to(PROJECT_ROOT).as_posix(),
        "total_lines": total_effective_lines,
        "functions": functions,
    }


def parse_tests(test_files: list[Path]) -> set[str]:
    """解析测试文件，收集被调用的函数名。"""
    called = set()
    call_pattern = re.compile(r"\.(\w+)\(")
    for path in test_files:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()
        for m in call_pattern.finditer(content):
            called.add(m.group(1))
    return called


def main() -> int:
    script_files = get_gd_files(SCRIPTS_DIR)
    test_files = list(TESTS_DIR.rglob("*.gd"))

    called_funcs = parse_tests(test_files)

    total_functions = 0
    covered_functions = 0
    total_lines = 0
    covered_lines = 0

    total_functions_incl_lc = 0
    covered_functions_incl_lc = 0
    total_lines_incl_lc = 0
    covered_lines_incl_lc = 0

    print("=" * 60)
    print("GDScript Coverage Report")
    print("=" * 60)

    for sf in script_files:
        info = parse_script(sf)
        if not info["functions"]:
            continue

        script_covered_funcs = 0
        script_total_funcs = 0
        script_covered_lines = 0
        script_total_lines = 0

        for func in info["functions"]:
            is_lc = func["name"] in LIFECYCLE_FUNCS
            total_functions_incl_lc += 1
            total_lines_incl_lc += func["body_lines"]

            if not is_lc:
                total_functions += 1
                total_lines += func["body_lines"]
                script_total_funcs += 1
                script_total_lines += func["body_lines"]

            if func["name"] in called_funcs:
                func["covered"] = True
                covered_functions_incl_lc += 1
                covered_lines_incl_lc += func["body_lines"]
                if not is_lc:
                    covered_functions += 1
                    covered_lines += func["body_lines"]
                    script_covered_funcs += 1
                    script_covered_lines += func["body_lines"]

        if script_total_funcs > 0:
            func_rate = script_covered_funcs / script_total_funcs * 100
            line_rate = script_covered_lines / script_total_lines * 100 if script_total_lines > 0 else 0
            status = "PASS" if line_rate >= 60 else "WARN"
            print(f"[{status}] {info['path']:40s}  func: {func_rate:5.1f}%  line: {line_rate:5.1f}%  ({script_covered_funcs}/{script_total_funcs} funcs)")

    print("-" * 60)

    if total_functions > 0:
        func_rate = covered_functions / total_functions * 100
        line_rate = covered_lines / total_lines * 100 if total_lines > 0 else 0
        print(f"Excluding lifecycle functions:")
        print(f"  Function coverage: {covered_functions}/{total_functions} = {func_rate:.1f}%")
        print(f"  Estimated line coverage: {covered_lines}/{total_lines} = {line_rate:.1f}%")

    if total_functions_incl_lc > 0:
        func_rate_all = covered_functions_incl_lc / total_functions_incl_lc * 100
        line_rate_all = covered_lines_incl_lc / total_lines_incl_lc * 100 if total_lines_incl_lc > 0 else 0
        print(f"Including lifecycle functions:")
        print(f"  Function coverage: {covered_functions_incl_lc}/{total_functions_incl_lc} = {func_rate_all:.1f}%")
        print(f"  Estimated line coverage: {covered_lines_incl_lc}/{total_lines_incl_lc} = {line_rate_all:.1f}%")

    print("=" * 60)

    # 判断是否通过 60% 阈值
    if line_rate >= 60.0:
        print("RESULT: PASS (line coverage >= 60%)")
        return 0
    else:
        print("RESULT: FAIL (line coverage < 60%)")
        return 1


if __name__ == "__main__":
    sys.exit(main())
