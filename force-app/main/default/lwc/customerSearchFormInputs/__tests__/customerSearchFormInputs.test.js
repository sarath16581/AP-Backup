import { createElement } from "lwc";
import CustomerSearchFormInputs from "c/customerSearchFormInputs";

// Import constants from component
import {
  SEARCH_FORM_TITLE,
  FIRST_NAME_LABEL,
  LAST_NAME_LABEL,
  PHONE_NUMBER_LABEL,
  EMAIL_ADDRESS_LABEL,
  SEARCH_BUTTON_LABEL,
  CLEAR_BUTTON_LABEL,
} from "c/customerSearchFormInputs";

/**
 * Finds and returns input field based on the `data-field-name` attribute.
 *
 * @param {Element} element
 * @param {string} fieldName
 * @returns
 */
function getInputField(element, fieldName) {
  return element.shadowRoot.querySelector(`[data-field-name='${fieldName}']`);
}

/**
 * Helper function to await DOM updates and event handlers
 */
function flushPromises() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

describe("c-customer-search-form-inputs", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    // Reset mocks
    jest.clearAllMocks();
  });

  it("shows component title", () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

    // Assert
    const cardCmp = element.shadowRoot.querySelector("lightning-card");
    expect(cardCmp).not.toBeNull();
    expect(cardCmp.title).toBe(SEARCH_FORM_TITLE);
  });

  it("shows search form input and button elements", () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

    // Assert
    const firstNameInput = getInputField(element, "firstName");
    expect(firstNameInput).not.toBeNull();
    expect(firstNameInput.type).toBe("text");
    expect(firstNameInput.label).toBe(FIRST_NAME_LABEL);
    expect(firstNameInput.placeholder).toBe(FIRST_NAME_LABEL);
    expect(firstNameInput.maxLength).toBe("40");
    expect(firstNameInput.value).toBe("");

    const lastNameInput = getInputField(element, "lastName");
    expect(lastNameInput).not.toBeNull();
    expect(lastNameInput.type).toBe("text");
    expect(lastNameInput.label).toBe(LAST_NAME_LABEL);
    expect(lastNameInput.placeholder).toBe(LAST_NAME_LABEL);
    expect(lastNameInput.maxLength).toBe("80");
    expect(lastNameInput.value).toBe("");

    const emailAddressInput = getInputField(element, "emailAddress");
    expect(emailAddressInput).not.toBeNull();
    expect(emailAddressInput.type).toBe("email");
    expect(emailAddressInput.label).toBe(EMAIL_ADDRESS_LABEL);
    expect(emailAddressInput.placeholder).toBe(EMAIL_ADDRESS_LABEL);
    expect(emailAddressInput.maxLength).toBe("80");
    expect(emailAddressInput.value).toBe("");

    const phoneNumberInput = getInputField(element, "phoneNumber");
    expect(phoneNumberInput).not.toBeNull();
    expect(phoneNumberInput.type).toBe("tel");
    expect(phoneNumberInput.label).toBe(PHONE_NUMBER_LABEL);
    expect(phoneNumberInput.placeholder).toBe(PHONE_NUMBER_LABEL);
    expect(phoneNumberInput.maxLength).toBe("40");
    expect(phoneNumberInput.value).toBe("");

    const buttons = [
      ...element.shadowRoot.querySelectorAll("lightning-button"),
    ];
    expect(buttons.length).toBe(2);

    const searchButton = buttons[0];
    expect(searchButton).not.toBeNull();
    expect(searchButton.label).toBe(SEARCH_BUTTON_LABEL);

    const clearButton = buttons[1];
    expect(clearButton).not.toBeNull();
    expect(clearButton.label).toBe(CLEAR_BUTTON_LABEL);
  });

  it("trims whitespace on input 'blur' event", async () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

    const firstNameInput = getInputField(element, "firstName");
    expect(firstNameInput).not.toBeNull();
    firstNameInput.value = "Joan ";
    firstNameInput.dispatchEvent(new CustomEvent("change"));
    firstNameInput.dispatchEvent(new CustomEvent("blur"));

    await flushPromises();

    // Assert
    expect(firstNameInput.value).toBe("Joan");
  });

  it("fires the 'inputchange' event when input field changed", async () => {
    // Arrange
    const element = createElement("c-customer-search-form-inputs", {
      is: CustomerSearchFormInputs,
    });

    // Act
    document.body.appendChild(element);

    const handler = jest.fn();
    element.addEventListener("inputchange", handler);

    // Trigger the click event on the search button
    const firstNameInput = getInputField(element, "firstName");
    expect(firstNameInput).not.toBeNull();
    firstNameInput.value = "Joan";
    firstNameInput.dispatchEvent(new CustomEvent("change"), {
      detail: { value: "Joan" },
    });

    // Wait for any asynchronous code to complete
    await flushPromises();

    // Assert
    expect(handler).toHaveBeenCalled();
    expect(handler.mock.calls[0][0].detail.fieldName).toEqual("firstName");
    expect(handler.mock.calls[0][0].detail.value).toEqual("Joan");
  });
});
