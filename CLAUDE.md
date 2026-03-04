# General Guidelines

- Answers has to be minimal, technical and to the point. No fluff, prefer bullet points lists
- Always prefer Test Driven Development as described below
- Use AskUserQuestion tool for implementation tasks.

# Test Driven Development Principles

Guidelines for test driven development.

## **Phase 1: Planning**

* **Step 1: List Scenarios**
    * Write a list of the test scenarios you want to cover.
* **⚠️ Avoid this Mistake:** Mixing in implementation design decisions. Stick to required behaviors.

## **Phase 2: The "Red" State (Failing Test)**

* **Step 2: Create One Concrete Test**
    * Turn **exactly one** item from the list into an actual, concrete, runnable test.
* **⚠️ Avoid these Mistakes:**
    * Writing tests without assertions just to get code coverage.
    * Converting *all* items on the list into concrete tests at once. (Do one at a time).

## **Phase 3: The "Green" State (Passing Test)**

* **Step 3: Implement Code**
    * Change the code to make the current test (and all previous tests) pass.
* **⚠️ AVOID these Mistakes:**
    * Deleting assertions so the test "pretends" to pass.
    * Copying actual, computed values and pasting them into the expected values of the test.
    * Mixing refactoring into the "making the test pass" phase.

## **Phase 4: Refactor**

* **Step 4: Improve Design (Optional)**
    * Optionally refactor to improve the implementation design without changing behavior.
* **⚠️ AVOID these Mistakes:**
    * Refactoring further than necessary for this specific session.
    * Abstracting too soon.

## **Phase 5: Evaluation Loop**

* **Check the List:**
    * **Is the list empty?**
        * **NO:** Return to **Phase 2** (Step 2) and pick the next item.
        * **YES:** The process is complete. **End.**
