import { useState } from "react";
import { ChevronRight, Wallet, CreditCard, Smartphone, CheckCircle, AlertCircle } from "lucide-react";
function TopUpWalletPage({ onBack, onComplete, currentBalance = 250 }) {
  const [selectedAmount, setSelectedAmount] = useState(null);
  const [customAmount, setCustomAmount] = useState("");
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState(null);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const quickAmounts = [50, 100, 200, 500, 1e3, 2e3];
  const paymentMethods = [
    {
      id: "credit-card",
      name: "\u0628\u0637\u0627\u0642\u0629 \u0627\u0626\u062A\u0645\u0627\u0646\u064A\u0629",
      nameEn: "Credit Card",
      icon: CreditCard,
      description: "Visa, Mastercard, Mada",
      color: "from-blue-500 to-blue-600"
    },
    {
      id: "apple-pay",
      name: "Apple Pay",
      nameEn: "Apple Pay",
      icon: Smartphone,
      description: "\u062F\u0641\u0639 \u0633\u0631\u064A\u0639 \u0648\u0622\u0645\u0646",
      color: "from-gray-800 to-black"
    },
    {
      id: "stc-pay",
      name: "STC Pay",
      nameEn: "STC Pay",
      icon: Wallet,
      description: "\u0627\u0644\u062F\u0641\u0639 \u0639\u0628\u0631 STC Pay",
      color: "from-purple-500 to-purple-600"
    },
    {
      id: "mada",
      name: "\u0645\u062F\u0649",
      nameEn: "Mada",
      icon: CreditCard,
      description: "\u0627\u0644\u0628\u0637\u0627\u0642\u0629 \u0627\u0644\u0648\u0637\u0646\u064A\u0629",
      color: "from-green-500 to-green-600"
    }
  ];
  const handleAmountSelect = (amount) => {
    setSelectedAmount(amount);
    setCustomAmount("");
  };
  const handleCustomAmountChange = (value) => {
    const numValue = value.replace(/[^\d]/g, "");
    setCustomAmount(numValue);
    if (numValue) {
      setSelectedAmount(parseInt(numValue));
    } else {
      setSelectedAmount(null);
    }
  };
  const handleTopUp = () => {
    if (selectedAmount && selectedPaymentMethod) {
      setShowConfirmation(true);
    }
  };
  const handleConfirm = () => {
    if (onComplete) {
      onComplete();
    }
  };
  const getFinalAmount = () => {
    return selectedAmount || 0;
  };
  const currentLang = localStorage.getItem("appLanguage") || "ar";
  const isArabic = currentLang === "ar";
  return <div className="flex-1 overflow-y-auto bg-background" dir={isArabic ? "rtl" : "ltr"}>
      {
    /* Header */
  }
      <div className="bg-gradient-to-br from-primary to-primary/90 text-white px-6 pt-8 pb-6">
        <div className="flex items-center gap-3 mb-4">
          <button onClick={onBack} className="p-2 bg-white/20 rounded-full backdrop-blur-sm hover:bg-white/30 transition-colors">
            {isArabic ? <ChevronRight className="w-5 h-5" /> : <ChevronRight className="w-5 h-5 rotate-180" />}
          </button>
          <h1 className="text-2xl">{isArabic ? "\u0634\u062D\u0646 \u0627\u0644\u0631\u0635\u064A\u062F" : "Top Up Balance"}</h1>
        </div>
        <p className="text-white/80 text-sm">
          {isArabic ? "\u0627\u062E\u062A\u0631 \u0627\u0644\u0645\u0628\u0644\u063A \u0648\u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639" : "Choose amount and payment method"}
        </p>
      </div>

      <div className="px-6 py-6 space-y-5">
        {
    /* Current Balance */
  }
        <div className="bg-gradient-to-br from-green-50 to-green-100/50 border-2 border-green-200 rounded-2xl p-5">
          <div className="flex items-center gap-3 mb-3">
            <div className="w-12 h-12 bg-green-500 rounded-full flex items-center justify-center">
              <Wallet className="w-6 h-6 text-white" />
            </div>
            <div>
              <p className="text-sm text-muted-foreground">
                {isArabic ? "\u0627\u0644\u0631\u0635\u064A\u062F \u0627\u0644\u062D\u0627\u0644\u064A" : "Current Balance"}
              </p>
              <p className="text-2xl text-green-600 font-bold">
                {currentBalance} {isArabic ? "\u0631.\u0633" : "SAR"}
              </p>
            </div>
          </div>
        </div>

        {
    /* Quick Amounts */
  }
        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
          <h3 className="text-secondary font-medium mb-4">
            {isArabic ? "\u0627\u062E\u062A\u0631 \u0627\u0644\u0645\u0628\u0644\u063A" : "Select Amount"}
          </h3>
          <div className="grid grid-cols-3 gap-3 mb-4">
            {quickAmounts.map((amount) => <button
    key={amount}
    onClick={() => handleAmountSelect(amount)}
    className={`py-3 rounded-xl border-2 transition-all ${selectedAmount === amount && !customAmount ? "bg-primary text-white border-primary" : "bg-gray-50 text-secondary border-border hover:border-primary"}`}
  >
                <span className="text-lg font-medium">{amount}</span>
                <span className="text-xs block mt-1">{isArabic ? "\u0631.\u0633" : "SAR"}</span>
              </button>)}
          </div>

          {
    /* Custom Amount */
  }
          <div className="relative">
            <label className="block text-sm text-muted-foreground mb-2">
              {isArabic ? "\u0623\u0648 \u0623\u062F\u062E\u0644 \u0645\u0628\u0644\u063A \u0645\u062E\u0635\u0635" : "Or enter custom amount"}
            </label>
            <div className="relative">
              <input
    type="text"
    value={customAmount}
    onChange={(e) => handleCustomAmountChange(e.target.value)}
    placeholder={isArabic ? "\u0623\u062F\u062E\u0644 \u0627\u0644\u0645\u0628\u0644\u063A" : "Enter amount"}
    className="w-full px-4 py-3 bg-gray-50 border-2 border-border rounded-xl text-secondary placeholder:text-muted-foreground focus:outline-none focus:border-primary transition-colors"
    dir="ltr"
  />
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground">
                {isArabic ? "\u0631.\u0633" : "SAR"}
              </span>
            </div>
            {customAmount && parseInt(customAmount) < 10 && <p className="text-xs text-red-600 mt-2 flex items-center gap-1">
                <AlertCircle className="w-3 h-3" />
                {isArabic ? "\u0627\u0644\u062D\u062F \u0627\u0644\u0623\u062F\u0646\u0649 \u0644\u0644\u0634\u062D\u0646 10 \u0631.\u0633" : "Minimum top-up is 10 SAR"}
              </p>}
          </div>
        </div>

        {
    /* Payment Methods */
  }
        <div className="bg-white border border-border rounded-2xl p-5 shadow-sm">
          <h3 className="text-secondary font-medium mb-4">
            {isArabic ? "\u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639" : "Payment Method"}
          </h3>
          <div className="space-y-3">
            {paymentMethods.map((method) => {
    const Icon = method.icon;
    return <button
      key={method.id}
      onClick={() => setSelectedPaymentMethod(method.id)}
      className={`w-full flex items-center gap-4 p-4 rounded-xl border-2 transition-all ${selectedPaymentMethod === method.id ? "bg-primary/5 border-primary" : "bg-gray-50 border-border hover:border-primary/50"}`}
    >
                  <div className={`w-12 h-12 bg-gradient-to-br ${method.color} rounded-xl flex items-center justify-center flex-shrink-0`}>
                    <Icon className="w-6 h-6 text-white" />
                  </div>
                  <div className={`flex-1 ${isArabic ? "text-right" : "text-left"}`}>
                    <p className="text-sm text-secondary font-medium">
                      {isArabic ? method.name : method.nameEn}
                    </p>
                    <p className="text-xs text-muted-foreground">{method.description}</p>
                  </div>
                  {selectedPaymentMethod === method.id && <CheckCircle className="w-5 h-5 text-primary flex-shrink-0" />}
                </button>;
  })}
          </div>
        </div>

        {
    /* Summary */
  }
        {selectedAmount && selectedPaymentMethod && <div className="bg-gradient-to-br from-blue-50 to-blue-100/50 border-2 border-blue-200 rounded-2xl p-5">
            <h3 className="text-secondary font-medium mb-3">
              {isArabic ? "\u0645\u0644\u062E\u0635 \u0627\u0644\u0639\u0645\u0644\u064A\u0629" : "Transaction Summary"}
            </h3>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">
                  {isArabic ? "\u0627\u0644\u0645\u0628\u0644\u063A \u0627\u0644\u0645\u0637\u0644\u0648\u0628:" : "Amount:"}
                </span>
                <span className="text-secondary font-medium">
                  {getFinalAmount()} {isArabic ? "\u0631.\u0633" : "SAR"}
                </span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-muted-foreground">
                  {isArabic ? "\u0631\u0633\u0648\u0645 \u0627\u0644\u0645\u0639\u0627\u0645\u0644\u0629:" : "Transaction Fee:"}
                </span>
                <span className="text-green-600 font-medium">
                  {isArabic ? "\u0645\u062C\u0627\u0646\u0627\u064B" : "Free"}
                </span>
              </div>
              <div className="h-px bg-blue-300 my-2" />
              <div className="flex justify-between items-center">
                <span className="text-secondary font-medium">
                  {isArabic ? "\u0627\u0644\u0631\u0635\u064A\u062F \u0627\u0644\u062C\u062F\u064A\u062F:" : "New Balance:"}
                </span>
                <span className="text-lg text-primary font-bold">
                  {currentBalance + getFinalAmount()} {isArabic ? "\u0631.\u0633" : "SAR"}
                </span>
              </div>
            </div>
          </div>}

        {
    /* Info Note */
  }
        <div className="bg-yellow-50 border border-yellow-200 rounded-2xl p-4">
          <div className="flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-xs text-secondary leading-relaxed">
                {isArabic ? "\u2022 \u0633\u064A\u062A\u0645 \u0625\u0636\u0627\u0641\u0629 \u0627\u0644\u0645\u0628\u0644\u063A \u0644\u0631\u0635\u064A\u062F\u0643 \u0641\u0648\u0631\u0627\u064B \u0628\u0639\u062F \u0625\u062A\u0645\u0627\u0645 \u0627\u0644\u062F\u0641\u0639\n\u2022 \u0627\u0644\u062D\u062F \u0627\u0644\u0623\u062F\u0646\u0649 \u0644\u0644\u0634\u062D\u0646 10 \u0631.\u0633\n\u2022 \u062C\u0645\u064A\u0639 \u0627\u0644\u0645\u0639\u0627\u0645\u0644\u0627\u062A \u0622\u0645\u0646\u0629 \u0648\u0645\u0634\u0641\u0631\u0629" : "\u2022 Amount will be added to your balance immediately after payment\n\u2022 Minimum top-up is 10 SAR\n\u2022 All transactions are secure and encrypted"}
              </p>
            </div>
          </div>
        </div>

        {
    /* Action Buttons */
  }
        <div className="flex gap-3 pt-4">
          <button
    onClick={onBack}
    className="px-6 py-3 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
            {isArabic ? "\u0631\u062C\u0648\u0639" : "Back"}
          </button>
          <button
    onClick={handleTopUp}
    disabled={!selectedAmount || selectedAmount < 10 || !selectedPaymentMethod}
    className={`flex-1 py-3 rounded-xl shadow-lg transition-all ${selectedAmount && selectedAmount >= 10 && selectedPaymentMethod ? "bg-gradient-to-r from-primary to-primary/90 text-white hover:shadow-xl" : "bg-gray-300 text-gray-500 cursor-not-allowed"}`}
  >
            {isArabic ? "\u0625\u062A\u0645\u0627\u0645 \u0627\u0644\u0634\u062D\u0646" : "Complete Top Up"}
          </button>
        </div>
      </div>

      {
    /* Confirmation Modal */
  }
      {showConfirmation && <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center p-6 z-50">
          <div className="bg-white rounded-3xl p-6 max-w-sm w-full shadow-2xl">
            <div className="flex justify-center mb-4">
              <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center">
                <Wallet className="w-8 h-8 text-green-600" />
              </div>
            </div>

            <h3 className="text-xl text-secondary text-center mb-2">
              {isArabic ? "\u062A\u0623\u0643\u064A\u062F \u0627\u0644\u0634\u062D\u0646" : "Confirm Top Up"}
            </h3>
            <p className="text-sm text-muted-foreground text-center mb-6">
              {isArabic ? `\u0647\u0644 \u0623\u0646\u062A \u0645\u062A\u0623\u0643\u062F \u0645\u0646 \u0634\u062D\u0646 ${getFinalAmount()} \u0631.\u0633\u061F` : `Are you sure you want to top up ${getFinalAmount()} SAR?`}
            </p>

            <div className="bg-gray-50 rounded-xl p-4 mb-6 space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">
                  {isArabic ? "\u0627\u0644\u0645\u0628\u0644\u063A:" : "Amount:"}
                </span>
                <span className="text-secondary font-medium">
                  {getFinalAmount()} {isArabic ? "\u0631.\u0633" : "SAR"}
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">
                  {isArabic ? "\u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639:" : "Payment Method:"}
                </span>
                <span className="text-secondary">
                  {isArabic ? paymentMethods.find((m) => m.id === selectedPaymentMethod)?.name : paymentMethods.find((m) => m.id === selectedPaymentMethod)?.nameEn}
                </span>
              </div>
              <div className="h-px bg-gray-200 my-2" />
              <div className="flex justify-between">
                <span className="text-muted-foreground">
                  {isArabic ? "\u0627\u0644\u0631\u0635\u064A\u062F \u0627\u0644\u062C\u062F\u064A\u062F:" : "New Balance:"}
                </span>
                <span className="text-green-600 font-medium">
                  {currentBalance + getFinalAmount()} {isArabic ? "\u0631.\u0633" : "SAR"}
                </span>
              </div>
            </div>

            <div className="flex gap-3">
              <button
    onClick={() => setShowConfirmation(false)}
    className="flex-1 py-3 px-4 bg-gray-100 text-secondary rounded-xl hover:bg-gray-200 transition-colors"
  >
                {isArabic ? "\u0625\u0644\u063A\u0627\u0621" : "Cancel"}
              </button>
              <button
    onClick={handleConfirm}
    className="flex-1 py-3 px-4 bg-gradient-to-r from-primary to-primary/90 text-white rounded-xl hover:shadow-lg transition-all"
  >
                {isArabic ? "\u062A\u0623\u0643\u064A\u062F" : "Confirm"}
              </button>
            </div>
          </div>
        </div>}
    </div>;
}
export {
  TopUpWalletPage as default
};
