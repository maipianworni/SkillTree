# Leaf SKILL.md Template

This template defines the structure for leaf node skill files.

---

## Template

```markdown
# {Feature Name} [LEAF NODE]

{Brief description of what this skill does and when to use it}

## Workflow

### Step 1: {First Step}
{Detailed instructions for this step}

### Step 2: {Second Step}
{Detailed instructions for this step}

### Step 3: {Third Step}
{Detailed instructions for this step}

## Examples

### Example 1: {Example Title}
**User Request**: {Example user prompt}
**Action**: {What Claude should do}

### Example 2: {Example Title}
**User Request**: {Example user prompt}
**Action**: {What Claude should do}

## Constraints

- {Constraint 1}
- {Constraint 2}
- {Constraint 3}

## Related Skills

- `{related-skill-1}` - {When to use this related skill}
- `{related-skill-2}` - {When to use this related skill}
```

---

## Required Elements

### 1. Title with LEAF NODE Marker

The `[LEAF NODE]` marker signals the router that this is a terminal node.

```markdown
# React Development [LEAF NODE]
```

### 2. Brief Description

One or two sentences explaining:
- What the skill does
- When it should be used

### 3. Workflow Steps

Numbered steps that Claude should follow:
- Each step should be actionable
- Include specific tool references when applicable
- Consider edge cases and error handling

### 4. Examples

Concrete examples help Claude understand:
- What user requests trigger this skill
- What actions to take
- What output to produce

### 5. Constraints

Important limitations or requirements:
- Scope boundaries
- Error conditions
- Dependencies
- Context requirements

---

## Complete Example

```markdown
# React Component Development [LEAF NODE]

This skill handles creating and modifying React components using functional
components with hooks. Use when the user requests React-specific development.

## Workflow

### Step 1: Understand Requirements
- Analyze the user's request for component functionality
- Identify required props and state
- Consider component composition patterns

### Step 2: Create Component Structure
- Use functional component syntax with arrow functions
- Define TypeScript interfaces for props
- Set up necessary hooks (useState, useEffect, useCallback, etc.)

### Step 3: Implement Component Logic
- Follow React best practices
- Use custom hooks for reusable logic
- Implement proper cleanup in useEffect

### Step 4: Add Styling
- Use CSS modules or styled-components based on project convention
- Ensure responsive design principles

## Examples

### Example 1: Creating a Button Component
**User Request**: "Create a reusable button component"
**Action**:
1. Create `Button.tsx` with TypeScript props interface
2. Include variant props (primary, secondary, outline)
3. Add onClick handler prop
4. Create corresponding CSS module

### Example 2: Adding Form Validation
**User Request**: "Add validation to my login form"
**Action**:
1. Install/verify react-hook-form dependency
2. Add validation rules to form fields
3. Implement error message display
4. Add form submission handling

## Constraints

- Always use functional components, not class components
- Use TypeScript for type safety
- Follow existing project conventions for styling
- Ensure accessibility (aria labels, keyboard navigation)

## Related Skills

- `css` - For styling and animations
- `typescript` - For type definitions
- `testing` - For component tests with Jest/React Testing Library
```

---

## Best Practices

1. **Single Responsibility**: Each leaf should handle one coherent task type
2. **Clear Triggers**: Make it obvious when this skill should be used
3. **Actionable Steps**: Steps should be concrete actions, not vague guidelines
4. **Realistic Examples**: Use examples that match actual user requests
5. **Boundary Clarity**: Explicitly state what this skill does NOT do
6. **Self-Containment [MANDATORY]**: ALL leaf nodes must be fully self-contained, whether executable instructions or reference data. Never create stub files that only contain a summary and a pointer to an external file. An agent loading only the tree must have everything needed to execute. This includes workflow steps, code examples, API specifications, lookup tables, and any data the original skill contained. If the original skill referenced an external file, read and inline that content during generation.
7.  **No Stub Patterns**: Do NOT use patterns like "Read the skill at {path}", "See {file} for details", or "Full Instructions: Read {path}". Every instruction must be directly in the leaf.
8.  **Fallback on Missing Source**: If the source skill content cannot be found, do NOT generate a stub. Either abort with an error listing missing skills, or generate a meaningful fallback with `[AUTO-GENERATED FALLBACK - NO SOURCE SKILL]` marker.
