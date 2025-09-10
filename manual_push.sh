#!/bin/bash

# HiCalendar手动推送脚本
# 用于手动触发推送通知

echo "🚀 正在执行推送..."

curl -X POST "https://ngzzciukzokypzzpcbvj.supabase.co/functions/v1/push-scheduler" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5nenpjaXVrem9reXB6enBjYnZqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NTY4MzcwNSwiZXhwIjoyMDcxMjU5NzA1fQ.V-JcSzeVbv7CL3zvKXjzsNfFsW-A8uDiK51G5mOxzU8" \
  -H "Content-Type: application/json" \
  -d '{}'

echo ""
echo "✅ 推送完成"