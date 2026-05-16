# 📂 Workspaces

In **NKP Starter**, a Workspace acts as a logical boundary that maps **1-to-1** with a Workload Cluster. 

By creating a folder for each Workspace, we achieve:
1. **Blast Radius Isolation**: Changes to Workspace 1 cannot accidentally break Workspace 2.
2. **Access Control**: You can use GitHub CODEOWNERS to restrict who can approve changes to specific workspaces.
