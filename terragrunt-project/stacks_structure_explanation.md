# Terragrunt Stacks File Structure & Variable Handling

In the **Stacks** approach (Explicit Stacks), you move away from the deep directory nesting of "Classic" Terragrunt (where directory structure = deployment structure) towards a flatter, configuration-driven approach.

## 1. The File Structure

Instead of a folder for every component in every environment, you typically have **one stack definition per environment** (or one generic stack definition reused by environment configurations).

### Comparison

**Classic Terragrunt:**
```text
├── dev/
│   ├── env.hcl
│   ├── vpc/
│   │   └── terragrunt.hcl
│   ├── app/
│   │   └── terragrunt.hcl
│   └── db/
│       └── terragrunt.hcl
└── prod/
    ├── env.hcl
    ├── vpc/
    │   └── terragrunt.hcl
    ├── app/
    │   └── terragrunt.hcl
    └── db/
        └── terragrunt.hcl
```

**Terragrunt Stacks (Explicit):**
```text
├── stacks/
│   └── main_stack.hcl      # The "Blueprint" defining the topology (VPC -> DB -> App)
├── environments/
│   ├── dev.hcl             # Variables for Dev
│   └── prod.hcl            # Variables for Prod
└── terragrunt.hcl          # (Optional) Global config
```

*Note: You can also place the stack file directly in environment folders if you prefer, but separating the "Stack Definition" (logic) from "Environment Values" (data) is cleaner.*

## 2. How it Works

You define the **Stack** once. It says "I need a VPC, a DB, and an App, and here is how they connect."

**`stacks/main_stack.hcl`**
```hcl
# Define inputs that this stack expects (loaded from env files later)
variable "environment" {}
variable "vpc_cidr" {}
variable "db_instance_type" {}

unit "vpc" {
  source = "git::https://github.com/my-org/modules.git//vpc"
  path   = "vpc"
  inputs = {
    cidr_block = var.vpc_cidr
    tags       = { Env = var.environment }
  }
}

unit "db" {
  source = "git::https://github.com/my-org/modules.git//db"
  path   = "db"
  inputs = {
    vpc_id        = unit.vpc.outputs.vpc_id  # Direct dependency reference!
    instance_type = var.db_instance_type
  }
}
```

## 3. Handling Differing Variables

You feed the variables into the stack at runtime or via a wrapper.

### Option A: The `terragrunt.hcl` Wrapper (Recommended)

You can keep a lightweight folder structure just to define the **environment context**, but use the **same stack file**.

**Structure:**
```text
├── dev/
│   ├── terragrunt.hcl   # Points to the stack + loads dev vars
│   └── values.hcl       # Dev specific values
└── prod/
    ├── terragrunt.hcl   # Points to the stack + loads prod vars
    └── values.hcl       # Prod specific values
```

**`dev/terragrunt.hcl`**
```hcl
# This is the "Root" for the dev environment stack
include "root" {
  path = find_in_parent_folders()
}

# Point to the stack definition
terraform {
  source = "../../stacks/main_stack.hcl"
}

# Load variables
inputs = merge(
  read_terragrunt_config("./values.hcl").inputs,
  {
    environment = "dev"
  }
)
```

**`dev/values.hcl`**
```hcl
inputs = {
  vpc_cidr         = "10.0.0.0/16"
  db_instance_type = "db.t3.micro"
}
```

### Option B: Direct CLI Usage (If supported by your version)

If using pure stacks without the wrapper (experimental), you might run:

```bash
terragrunt stack apply --config stacks/main_stack.hcl --var-file environments/dev.hcl
```

## Summary

*   **Logic (Stack)**: Lives in one file (`main_stack.hcl`). Defines *what* to deploy and *how* they connect.
*   **Data (Vars)**: Lives in separate files (`dev.hcl`, `prod.hcl`). Defines *how big* or *what flavor* to deploy.
*   **Result**: You delete dozens of `terragrunt.hcl` files and replace them with a single topology definition.
