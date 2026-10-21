---
title: Exchange RBAC
date: 2026-07-23
category: PowerShell
---

# Exchange Online Application RBAC

> **Give your applications access to Exchange — without giving them access to every mailbox.**

Microsoft Graph application permissions such as Mail.Send and Mail.ReadWrite are powerful.

Sometimes **too powerful**.

If an application only needs to send email from:

```
automation@contoso.com
```

why should it have permission across your entire organization?

That's where **Exchange Online Application RBAC** comes in.

---

## The Idea

Exchange RBAC lets us define three things:

### 👤 WHO

**Service Principal**

The application or Managed Identity receiving access.

### 🔑 WHAT

**Application Role**

What the application is allowed to do.

### 🎯 WHERE

**Management Scope**

Which Exchange recipients it can do it against.

Put them together:

```
Service Principal
       +
Application Role
       +
Management Scope
       ↓
  Role Assignment
```

For this example:

```
Automation App
       +
Mail.Send
       +
automation@contoso.com
       ↓
Send email from this mailbox only
```

---

# 1 — Connect to Exchange Online

Exchange Application RBAC is configured through the **Exchange Online Management PowerShell module**.

Install it:

```
Install-Module ExchangeOnlineManagement
```

Connect:

```
Connect-ExchangeOnline
```

> 💡 You'll need an account with the appropriate Exchange administrative permissions.

---

# 2 — Register the Service Principal

Our first component is **WHO** receives access.

Get the Name, App ID, and Object ID of your App Registration or Managed Identity's Service Principal from Entra ID.

```
$spName     = "Automation App"
$spAppId    = "11111111-1111-1111-1111-111111111111"
$spObjectId = "22222222-2222-2222-2222-222222222222"
```

Your Service Principal already exists in Entra ID, but Exchange Online needs its own reference to it.

Register it:

```
New-ServicePrincipal `
    -AppId $spAppId `
    -ObjectId $spObjectId `
    -DisplayName $spName
```

Verify:

```
Get-ServicePrincipal
```

### ✓ Component One Complete

```
WHO
 ↓
Automation App
```

---

# 3 — Create the Management Scope

Now we define **WHERE** the application can operate.

Our application only needs access to:

```
automation@contoso.com
```

Store it:

```
$scope = "automation@contoso.com"
```

Exchange Management Scopes use **recipient filters** to determine which recipients are included.

Before creating one, test the filter:

```
Get-Recipient `
    -RecipientPreviewFilter "EmailAddresses -eq '$scope'"
```

You should only see the mailbox you intend to target.

> 💡 **Always test your filter first.**
>
> The recipients returned by the filter are the recipients you're preparing to place inside the scope.

Now create it:

```
New-ManagementScope `
    -Name $scope `
    -RecipientRestrictionFilter "EmailAddresses -eq '$scope'"
```

### ✓ Component Two Complete

```
WHERE
  ↓
automation@contoso.com
```

### ⚠️ Organization Customization

If Exchange returns an error telling you organization customization must first be enabled, run:

```
Enable-OrganizationCustomization
```

Then create the scope again.

---

# 4 — Choose the Application Role

Now we decide **WHAT** our application can do.

View the available Exchange application roles:

```
Get-ManagementRole |
    Where-Object Name -Like "Application*" |
    Format-Table Name, Description
```

You'll find roles for mail, calendars, contacts, and other Exchange functionality.

For this example, we only need:

```
Application Mail.Send
```

Store it:

```
$role = "Application Mail.Send"
```

### ✓ Component Three Complete

```
WHAT
 ↓
Mail.Send
```

---

# 5 — Put It All Together

We now have everything we need.

```
WHO                     WHAT                    WHERE
 ↓                        ↓                       ↓

Automation App    +    Mail.Send    +    automation@contoso.com
```

Create the Management Role Assignment:

```
New-ManagementRoleAssignment `
    -Name "$spName Mail.Send $scope" `
    -App $spObjectId `
    -Role $role `
    -CustomResourceScope $scope
```

That's it.

Our application now has **Application Mail.Send**, restricted by our Management Scope.

---

# 6 — Prove It

Don't just assume the assignment works.

Test the mailbox that's supposed to be allowed:

```
Test-ServicePrincipalAuthorization `
    -Identity $spObjectId `
    -Resource "automation@contoso.com"
```

Look for:

```
InScope : True
```

Now try another mailbox:

```
Test-ServicePrincipalAuthorization `
    -Identity $spObjectId `
    -Resource "user@contoso.com"
```

Our assignment doesn't authorize the application against that recipient.

### The Result

```
automation@contoso.com     ✓ ALLOWED

user@contoso.com           ✗ OUT OF SCOPE
```

That's the whole point of Exchange Application RBAC.

---

# Scopes Can Be Much Bigger

A Management Scope doesn't have to represent **one mailbox**.

Remember — it's built using a filter.

For example:

```
Department -eq 'Finance'
```

could create a scope containing your Finance recipients.

```
FINANCE SCOPE

Finance User 1       ✓
Finance User 2       ✓
Finance User 3       ✓

HR User              ✗
IT User              ✗
```

The application role applies only within that scope.

This means you could even combine:

```
Application Exchange Full Access
                +
       Finance Management Scope
                ↓
   Full Exchange Access
   to Finance recipients only
```

That's where Management Scopes become extremely powerful.

---

# Give the Application Multiple Roles

You're not limited to one application role either.

For example:

```
$roles = @(
    "Application Mail.Send"
    "Application Mail.ReadWrite"
    "Application Calendars.ReadWrite"
    "Application Contacts.ReadWrite"
)

foreach ($role in $roles) {

    $params = @{
        Name                = "$spName $($role -replace 'Application ', '') $scope"
        App                 = $spObjectId
        Role                = $role
        CustomResourceScope = $scope
    }

    New-ManagementRoleAssignment @params
}
```

Now the same identity has several capabilities, while still being restricted by the same Management Scope.

```
Automation App
      │
      ├── Mail.Send
      ├── Mail.ReadWrite
      ├── Calendars.ReadWrite
      └── Contacts.ReadWrite
                │
                ▼
        Management Scope
                │
                ▼
       Selected recipients
```

---

# ⚠️ Don't Forget About Graph Permissions

There's one important catch.

**Permissions granted through Entra and Exchange RBAC are additive.**

Imagine your application already has this through Entra:

```
Microsoft Graph
     ↓
Mail.ReadWrite
     ↓
Organization-wide
```

You then create:

```
Exchange RBAC
     ↓
Application Mail.ReadWrite
     +
automation@contoso.com
```

The Exchange scope does **not** restrict the permission that was already granted through Entra.

The application still retains its organization-wide access.

### Keep it simple

**Want access to specific Exchange recipients?**

→ Use **Exchange Application RBAC**

**Intentionally want organization-wide access?**

→ Use the **Graph application permission through Entra**

Don't accidentally grant both and assume the Exchange scope overrides the broader permission.

---

# Useful Commands

### Service Principals

```
Get-ServicePrincipal
```

### Management Scopes

```
Get-ManagementScope
```

### Preview a Scope

```
Get-Recipient `
    -RecipientPreviewFilter "EmailAddresses -eq '$scope'"
```

### Available Application Roles

```
Get-ManagementRole |
    Where-Object Name -Like "Application*"
```

### Role Assignments

```
Get-ManagementRoleAssignment `
    -RoleAssigneeType ServicePrincipal
```

### Test Authorization

```
Test-ServicePrincipalAuthorization `
    -Identity $spObjectId `
    -Resource "automation@contoso.com"
```

---

# The Big Picture

If you remember nothing else, remember these three questions:

### 👤 WHO gets access?

**Service Principal**

### 🔑 WHAT can it do?

**Application Role**

### 🎯 WHERE can it do it?

**Management Scope**

Together:

```
WHO                     WHAT                    WHERE

Service Principal  +   Application Role   +   Management Scope
                           ↓
                    Role Assignment
```

Instead of saying:

> **"This application can access Exchange."**

we can say:

> **"This application can perform this specific action against these specific Exchange recipients."**

And that's a much better place to be.
