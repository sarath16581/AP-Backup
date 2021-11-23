import { NavigationMixin } from 'lightning/navigation';

const CHANGE_PASSWORD_PAGE_NAME = 'ChangePassword'
const UPDATE_USER_PROFILE_PAGE_NAME = 'UpdateProfile'
const ENQUIRY_DETAIL_PAGE_NAME = 'EnquiryDetail'
const CONSIGNMENT_TRACKING_PAGE_NAME = 'SearchConsignment'

export const navigation = (communityURL) => {
    communityURL = communityURL || ''
    return {
        bspHomePageURL: `${communityURL}/s/`,
        updateUserProfileURL: `${communityURL}/s/${UPDATE_USER_PROFILE_PAGE_NAME}`,
        changePasswordURL: `${communityURL}/s/${CHANGE_PASSWORD_PAGE_NAME}`,
        logoutURL: `${communityURL}/s/secur/logout.jsp`,
        enquiryDetailURL: `${communityURL}/s/${ENQUIRY_DETAIL_PAGE_NAME}`,
        trackingSearchPageURL: `${communityURL}/s/${CONSIGNMENT_TRACKING_PAGE_NAME}`,

        toHome: () => {
            const bspHomePageURL = `${communityURL}/s/`
            history.pushState({}, "home", bspHomePageURL)
            window.location = bspHomePageURL
        },
        toUserProfileEditPage: () => {
            const userEditPageURL = `${communityURL}/s/${UPDATE_USER_PROFILE_PAGE_NAME}`
            history.pushState({}, "userEditPage", userEditPageURL)
            window.location = userEditPageURL
        },
        toChangePasswordPage: () => {
            const changePasswordPageURL = `${communityURL}/s/${CHANGE_PASSWORD_PAGE_NAME}`
            history.pushState({}, "changePasswordPage", changePasswordPageURL)
            window.location = changePasswordPageURL
        },
        toLogout: () => {
            const logoutURL = `${communityURL}/s/secur/logout.jsp`
            history.pushState({}, "logout", logoutURL)
            window.location = logoutURL
        }
    }
}