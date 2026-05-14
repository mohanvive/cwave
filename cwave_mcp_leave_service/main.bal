import ballerina/mcp;

// Leave record to hold leave request details
type LeaveRequest record {|
    string employeeName;
    string leaveType;
    string startDate;
    string endDate;
    int numberOfDays;
    string status;
|};

// Employee leave data record
type EmployeeLeaveData record {|
    int annualBalance;
    int sickBalance;
    int casualBalance;
    LeaveRequest[] leaveHistory;
|};

// In-memory leave data store for employees
map<EmployeeLeaveData> leaveStore = {
    "James": {
        annualBalance: 14,
        sickBalance: 7,
        casualBalance: 5,
        leaveHistory: []
    },
    "John": {
        annualBalance: 10,
        sickBalance: 7,
        casualBalance: 3,
        leaveHistory: []
    },
    "Jinger": {
        annualBalance: 12,
        sickBalance: 7,
        casualBalance: 5,
        leaveHistory: []
    }
};

listener mcp:Listener mcpListener = new (8080);

@mcp:ServiceConfig {
    info: {
        name: "EmployeeLeaveServer",
        version: "1.0.0"
    },
    options: {
        instructions: "This server manages employee leave requests for James, John, and Jinger. Use the available tools to check leave balances, apply for leave, approve or reject leave, and view leave history."
    }
}
service mcp:Service /mcp on mcpListener {

    # Get the leave balance for an employee. Returns annual, sick, and casual leave balances.
    # Supported employees: James, John, Jinger.
    #
    # + employeeName - Name of the employee
    # + return - Leave balance summary or an error
    @mcp:Tool {
        description: "Get the leave balance for an employee. Returns annual, sick, and casual leave balances. Supported employees: James, John, Jinger."
    }
    remote function getLeaveBalance(string employeeName) returns string|error {
        if !leaveStore.hasKey(employeeName) {
            return error(string `Employee '${employeeName}' not found. Supported employees: James, John, Jinger.`);
        }
        EmployeeLeaveData employeeData = leaveStore.get(employeeName);
        return string `Leave Balance for ${employeeName}:
  Annual Leave : ${employeeData.annualBalance} days
  Sick Leave   : ${employeeData.sickBalance} days
  Casual Leave : ${employeeData.casualBalance} days`;
    }

    # Apply for leave on behalf of an employee.
    # leaveType must be 'annual', 'sick', or 'casual'. Dates should be in YYYY-MM-DD format.
    # Supported employees: James, John, Jinger.
    #
    # + employeeName - Name of the employee
    # + leaveType - Type of leave: annual, sick, or casual
    # + startDate - Start date in YYYY-MM-DD format
    # + endDate - End date in YYYY-MM-DD format
    # + numberOfDays - Number of leave days requested
    # + return - Confirmation message or an error
    @mcp:Tool {
        description: "Apply for leave on behalf of an employee. leaveType must be 'annual', 'sick', or 'casual'. Dates should be in YYYY-MM-DD format. Supported employees: James, John, Jinger."
    }
    remote function applyLeave(string employeeName, string leaveType, string startDate, string endDate, int numberOfDays) returns string|error {
        if !leaveStore.hasKey(employeeName) {
            return error(string `Employee '${employeeName}' not found. Supported employees: James, John, Jinger.`);
        }
        string normalizedType = leaveType.toLowerAscii();
        if normalizedType != "annual" && normalizedType != "sick" && normalizedType != "casual" {
            return error("Invalid leave type. Must be 'annual', 'sick', or 'casual'.");
        }
        EmployeeLeaveData employeeData = leaveStore.get(employeeName);
        int availableBalance = 0;
        if normalizedType == "annual" {
            availableBalance = employeeData.annualBalance;
        } else if normalizedType == "sick" {
            availableBalance = employeeData.sickBalance;
        } else {
            availableBalance = employeeData.casualBalance;
        }
        if availableBalance < numberOfDays {
            return string `Insufficient ${normalizedType} leave balance. Available: ${availableBalance} days, Requested: ${numberOfDays} days.`;
        }
        LeaveRequest newRequest = {
            employeeName: employeeName,
            leaveType: normalizedType,
            startDate: startDate,
            endDate: endDate,
            numberOfDays: numberOfDays,
            status: "Pending"
        };
        employeeData.leaveHistory.push(newRequest);
        return string `Leave application submitted successfully for ${employeeName}.
  Type      : ${normalizedType}
  From      : ${startDate}
  To        : ${endDate}
  Days      : ${numberOfDays}
  Status    : Pending`;
    }

    # Approve or reject a pending leave request for an employee.
    # action must be 'approve' or 'reject'. requestIndex is the 0-based index of the leave request in the employee's history.
    # Supported employees: James, John, Jinger.
    #
    # + employeeName - Name of the employee
    # + requestIndex - 0-based index of the leave request in the employee's history
    # + action - Action to perform: approve or reject
    # + return - Status message or an error
    @mcp:Tool {
        description: "Approve or reject a pending leave request for an employee. action must be 'approve' or 'reject'. requestIndex is the 0-based index of the leave request in the employee's history. Supported employees: James, John, Jinger."
    }
    remote function updateLeaveStatus(string employeeName, int requestIndex, string action) returns string|error {
        if !leaveStore.hasKey(employeeName) {
            return error(string `Employee '${employeeName}' not found. Supported employees: James, John, Jinger.`);
        }
        string normalizedAction = action.toLowerAscii();
        if normalizedAction != "approve" && normalizedAction != "reject" {
            return error("Invalid action. Must be 'approve' or 'reject'.");
        }
        EmployeeLeaveData employeeData = leaveStore.get(employeeName);
        int historyLength = employeeData.leaveHistory.length();
        if requestIndex < 0 || requestIndex >= historyLength {
            return error(string `Invalid request index ${requestIndex}. Employee has ${historyLength} leave request(s).`);
        }
        LeaveRequest leaveRequest = employeeData.leaveHistory[requestIndex];
        if leaveRequest.status != "Pending" {
            return string `Leave request at index ${requestIndex} is already '${leaveRequest.status}'. Only pending requests can be updated.`;
        }
        if normalizedAction == "approve" {
            employeeData.leaveHistory[requestIndex].status = "Approved";
            if leaveRequest.leaveType == "annual" {
                employeeData.annualBalance -= leaveRequest.numberOfDays;
            } else if leaveRequest.leaveType == "sick" {
                employeeData.sickBalance -= leaveRequest.numberOfDays;
            } else {
                employeeData.casualBalance -= leaveRequest.numberOfDays;
            }
            return string `Leave request approved for ${employeeName}. ${leaveRequest.numberOfDays} ${leaveRequest.leaveType} leave day(s) deducted from balance.`;
        } else {
            employeeData.leaveHistory[requestIndex].status = "Rejected";
            return string `Leave request rejected for ${employeeName}.`;
        }
    }

    # Get the full leave request history for an employee.
    # Supported employees: James, John, Jinger.
    #
    # + employeeName - Name of the employee
    # + return - Leave history summary or an error
    @mcp:Tool {
        description: "Get the full leave request history for an employee. Supported employees: James, John, Jinger."
    }
    remote function getLeaveHistory(string employeeName) returns string|error {
        if !leaveStore.hasKey(employeeName) {
            return error(string `Employee '${employeeName}' not found. Supported employees: James, John, Jinger.`);
        }
        EmployeeLeaveData employeeData = leaveStore.get(employeeName);
        int historyLength = employeeData.leaveHistory.length();
        if historyLength == 0 {
            return string `No leave history found for ${employeeName}.`;
        }
        string result = string `Leave History for ${employeeName} (${historyLength} request(s)):`;
        foreach int idx in 0 ..< historyLength {
            LeaveRequest leaveRequest = employeeData.leaveHistory[idx];
            result += string `
[${idx}] Type: ${leaveRequest.leaveType} | From: ${leaveRequest.startDate} | To: ${leaveRequest.endDate} | Days: ${leaveRequest.numberOfDays} | Status: ${leaveRequest.status}`;
        }
        return result;
    }

    # List all employees registered in the leave management system.
    #
    # + return - Comma-separated list of employee names or an error
    @mcp:Tool {
        description: "List all employees registered in the leave management system."
    }
    remote function listEmployees() returns string|error {
        string[] employeeNames = leaveStore.keys();
        return string `Registered employees: ${string:'join(", ", ...employeeNames)}`;
    }
}
