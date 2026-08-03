class AppStrings {
  static const String appName = 'TaskEasy';
  static const String manageEverything = 'Manage Everything';
  static const String manageYourTasks = 'Manage your tasks';
  static const String taskDetails = 'Task Details';
  static const String completed = 'Completed';
  static const String due = 'Due';
  static const String created = 'Created';
  static const String edit = 'Edit';
  static const String closing = 'Closing...';
  static const String closeTask = 'Close Task';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';

  // task list
  static const String noTasksYet = 'No tasks yet';

  // task filter & sort
  static const String filterAndSort = 'Filter & Sort';
  static const String filterTooltip = 'Filter and sort tasks';
  static const String statusLabel = 'Status';
  static const String sortByLabel = 'Sort By';
  static const String dateLabel = 'Date';
  static const String all = 'All';
  static const String today = 'Today';
  static const String tomorrow = 'Tomorrow';
  static const String customDate = 'Custom Date';
  static const String apply = 'Apply';
  static const String clearAll = 'Clear All';

  // task form
  static const String createTask = 'Create Task';
  static const String editTaskTitle = 'Edit Task';
  static const String deleteTask = 'Delete Task';
  static const String deleteTaskConfirmation = 'This action cannot be undone.';
  static const String taskNameLabel = 'Task Name';
  static const String descriptionLabel = 'Description';
  static const String priorityLabel = 'Priority';
  static const String dueDateLabel = 'Due Date';
  static const String dueTimeLabel = 'Due Time';
  static const String saving = 'Saving...';
  static const String creating = 'Creating...';
  static const String deleting = 'Deleting...';
  static const String saveChanges = 'Save Changes';

  // task form validation
  static const String pleaseSelectPriority = 'Please select a priority';
  static const String taskNameRequired = 'Task name is required';
  static const String descriptionRequired = 'Description is required';
  static const String dueDateRequired = 'Due date is required';
  static const String dueTimeRequired = 'Due time is required';
  static const String couldNotCreateTask = 'Could not create task. Please try again.';

  // tooltips
  static const String backTooltip = 'Back';
  static const String closeTooltip = 'Close';
  static const String editTaskTooltip = 'Edit task';
  static const String showPassword = 'Show password';
  static const String hidePassword = 'Hide password';

  // default texts
  static const String untitledTask = 'Untitled Task';
  static const String noDescriptionProvided = 'No description provided.';
  static const String noCreationDate = 'No creation date';
  static const String noDueDate = 'No due date';

  // settings
  static const String settings = 'Settings';

  // bottom navigation
  static const String tasksTab = 'Tasks';
  static const String expensesTab = 'Expenses';
  static const String remindersTab = 'Reminders';
  static const String journalTab = 'Journal';
  static const String remindersComingSoon = 'Reminders are coming soon';
  static const String journalComingSoon = 'Journal is coming soon';

  // expense list
  static const String manageYourExpenses = 'Manage your expenses';
  static const String noExpensesYet = 'No expenses yet';
  static const String currencySymbol = '₹';

  // expense form
  static const String createExpense = 'Create Expense';
  static const String editExpenseTitle = 'Edit Expense';
  static const String deleteExpense = 'Delete Expense';
  static const String deleteExpenseConfirmation = 'This action cannot be undone.';
  static const String expenseTitleLabel = 'Title';
  static const String amountLabel = 'Amount';
  static const String categoryLabel = 'Category';
  static const String expenseTitleRequired = 'Title is required';
  static const String amountRequired = 'Amount is required';
  static const String invalidAmount = 'Enter a valid amount';
  static const String categoryRequired = 'Please select a category';
  static const String expenseDateRequired = 'Date is required';
  static const String couldNotCreateExpense = 'Could not create expense. Please try again.';
  static const String editExpenseTooltip = 'Edit expense';

  // settings screen
  static const String checkServerHealth = 'Check Server Health';
  static const String checkingServerHealth = 'Checking...';
  static const String serverDown = 'Server down';
  static const String darkMode = 'Dark Mode';

  // auth
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String welcomeBack = 'Welcome Back';
  static const String createAccount = 'Create Account';
  static const String signInSubtitle = 'Sign in to continue managing your tasks';
  static const String signUpSubtitle = 'Create an account to get started';
  static const String fullNameLabel = 'Full Name';
  static const String emailLabel = 'Email';
  static const String passwordLabel = 'Password';
  static const String confirmPasswordLabel = 'Confirm Password';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String signingIn = 'Signing In...';
  static const String creatingAccount = 'Creating Account...';
  static const String logOut = 'Log Out';

  // auth validation
  static const String fullNameRequired = 'Full name is required';
  static const String emailRequired = 'Email is required';
  static const String invalidEmail = 'Enter a valid email address';
  static const String passwordRequired = 'Password is required';
  static const String passwordTooShort = 'Password must be at least 8 characters';
  static const String confirmPasswordRequired = 'Please confirm your password';
  static const String passwordsDoNotMatch = 'Passwords do not match';

  // groups
  static const String groups = 'Groups';
  static const String groupsTooltip = 'Groups';
  static const String noGroupsYet = 'No groups yet';
  static const String noGroupsSubtitle = 'Create a group, or join one with an invite code, to get started.';
  static const String createGroup = 'Create Group';
  static const String joinGroup = 'Join Group';
  static const String active = 'Active';
  static const String owner = 'Owner';
  static const String member = 'Member';
  static const String couldNotLoadGroups = 'Could not load groups. Please try again.';

  // create / join group
  static const String groupNameLabel = 'Group Name';
  static const String groupNameRequired = 'Group name is required';
  static const String inviteCodeLabel = 'Invite Code';
  static const String inviteCodeRequired = 'Invite code is required';
  static const String groupCreated = 'Group Created';
  static const String shareThisCode = 'Share this code with anyone you want to invite.';
  static const String inviteCodeCopied = 'Invite code copied';
  static const String copy = 'Copy';
  static const String share = 'Share';
  static const String done = 'Done';
  static const String join = 'Join';
  static const String joining = 'Joining...';
  static const String couldNotCreateGroup = 'Could not create group. Please try again.';
  static const String couldNotJoinGroup = 'Could not join group. Please try again.';
  static const String viewInviteCodeTooltip = 'View invite code';

  // group-scoped task/expense screens
  static const String allGroups = 'All Groups';
  static const String thisGroup = 'This Group';
  static const String noActiveGroupMessage = 'You need to create or join a group before adding tasks or expenses.';
  static const String goToGroups = 'Go to Groups';

  // assignee / payer / splits
  static const String assigneeLabel = 'Assignee';
  static const String assignedToLabel = 'Assigned To';
  static const String youSuffix = ' (You)';
  static const String payerLabel = 'Paid By';
  static const String splitsLabel = 'Split Between';
  static const String splitEqually = 'Split Equally';
  static const String amountOwedLabel = 'Amount';
  static const String selectAtLeastOneMember = 'Select at least one member to split with';
  static const String splitsMismatchError = 'Split amounts must add up to the total amount';
}
