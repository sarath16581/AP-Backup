const ACCESS_MANAGEMENT_PAGE_NAME = 'access-management'
const ACCESS_MANAGEMENT_USER_PAGE_NAME = 'access-management-user'

export const navigation = (communityURL) => {
    communityURL = communityURL || ''
    return {
        userTablePageURL: `${communityURL}/s/${ACCESS_MANAGEMENT_PAGE_NAME}`,
        bamHomePageURL: `${communityURL}/s/`,
        userPageURL: `${communityURL}/s/${ACCESS_MANAGEMENT_USER_PAGE_NAME}`,
        logoutURL: `${communityURL}/secur/logout.jsp`,

        toUsers: () => {
            const userTablePageURL = `${communityURL}/s/${ACCESS_MANAGEMENT_PAGE_NAME}`
            history.pushState({}, "userTable", userTablePageURL)
            window.location = userTablePageURL
        },
        toHome: () => {
            const bamHomePageURL =  `${communityURL}/s/`
            history.pushState({}, "home", bamHomePageURL)
            window.location = bamHomePageURL
        },
        toUserEditPage: (id) => {
            const userEditPageURL = `${communityURL}/s/${ACCESS_MANAGEMENT_USER_PAGE_NAME}?userId=${id}`
            history.pushState({}, "userEditPage", userEditPageURL)
            window.location = userEditPageURL
        },
        toUserCreatePage: () => {
            const userCreatePageURL = `${communityURL}/s/${ACCESS_MANAGEMENT_USER_PAGE_NAME}?createUser=true`
            history.pushState({}, "userCreatePage", userCreatePageURL)
            window.location = userCreatePageURL  
        },
        toMyAccessPage: () => {
            const userPageURL = `${communityURL}/s/${ACCESS_MANAGEMENT_USER_PAGE_NAME}`
            history.pushState({}, "myAccessPage", userPageURL)
            window.location = userPageURL 
        }
    }
}