import re

with open("/Users/sayarpaul/Project/puja24_backend/routes/groups.py", "r") as f:
    content = f.read()

replacement = """def get_my_groups(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    # Fetch all groups where the current user is a member
    memberships = db.query(GroupMember).filter(GroupMember.user_id == current_user.id).all()
    group_ids = [m.group_id for m in memberships]
    groups = db.query(Group).filter(Group.id.in_(group_ids)).all()
    
    result = []
    for g in groups:
        count = db.query(GroupMember).filter(GroupMember.group_id == g.id).count()
        g_dict = {
            "id": str(g.id),
            "name": g.name,
            "join_code": g.join_code,
            "picture_url": g.picture_url,
            "admin_id": str(g.admin_id),
            "created_at": g.created_at.isoformat(),
            "member_count": count
        }
        result.append(g_dict)
    return result
"""

# Regex to find get_my_groups and replace it until the next @router
content = re.sub(
    r"def get_my_groups\(.*?return groups\n", 
    replacement, 
    content, 
    flags=re.DOTALL
)

with open("/Users/sayarpaul/Project/puja24_backend/routes/groups.py", "w") as f:
    f.write(content)
