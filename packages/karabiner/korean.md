- 한영키 설정 + keyboard shortcut에서 input source - next source 를 f18로 수정
```json
{
    "description": "R_CMD to switch input languages like R_ALT in Windows (especially Korean)",
    "manipulators": [
        {
            "from": { "key_code": "right_gui" },
            "to": { "key_code": "f18" },
            "type": "basic"
        }
    ]
}
```
