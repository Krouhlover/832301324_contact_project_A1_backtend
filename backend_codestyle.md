# Backend Code Style Guide

> **Source:**  
> Based on [PEP 8 – Style Guide for Python Code](https://peps.python.org/pep-0008/)

## 1. General Rules

- 使用 UTF-8 编码  
- 缩进统一为 **4 个空格**  
- 每行不超过 79 个字符  
- 文件命名使用小写字母和下划线（如 `contacts.py`, `run.py`）  
- 类名使用命名（如 `ContactManager`）  
- 函数与变量使用小写字母+下划线（如 `add_contact`, `get_all_contacts`）

## 2. Import Rules

- 导入顺序遵循三层结构：  
  1️⃣ 标准库  
  2️⃣ 第三方库（如 Flask, SQLite3）  
  3️⃣ 本地模块（如 `controller.contacts`）  
- 导入示例：
  ```python
  import sqlite3
  from flask import Flask, jsonify, request
  from controller.contacts import contacts_bp
