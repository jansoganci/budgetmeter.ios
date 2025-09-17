const { createApp } = Vue;

createApp({
    data() {
        return {
            sessionStartTime: new Date(),
            sessionTime: '0 saat 0 dakika 0 saniye',
            liveExpense: 0,
            liveCounterKey: 0,
            intervalId: null,
            liveExpenseIntervalId: null,
            liveIncomeIntervalId: null,
            activeTab: 'expense', // Default to expense tab
            
            
            // Predefined categories
            predefinedDaily: [
                { id: 'yemek', name: 'Yemek', icon: '🍽️', amount: 0, frequency: 'daily' },
                { id: 'cay_kahve', name: 'Çay/Kahve', icon: '☕', amount: 0, frequency: 'daily' },
                { id: 'sigara', name: 'Sigara', icon: '🚬', amount: 0, frequency: 'daily' },
                { id: 'ulasim', name: 'Ulaşım', icon: '🚌', amount: 0, frequency: 'daily' },
                { id: 'diger', name: 'Diğer', icon: '💰', amount: 0, frequency: 'daily' },
            ],
            
            predefinedMonthly: [
                { id: 'kira', name: 'Kira', icon: '🏠', amount: 0, frequency: 'monthly' },
                { id: 'elektrik', name: 'Elektrik', icon: '⚡', amount: 0, frequency: 'monthly' },
                { id: 'su', name: 'Su', icon: '💧', amount: 0, frequency: 'monthly' },
                { id: 'dogalgaz', name: 'Doğalgaz', icon: '🔥', amount: 0, frequency: 'monthly' },
                { id: 'internet', name: 'İnternet', icon: '🌐', amount: 0, frequency: 'monthly' },
                { id: 'telefon', name: 'Telefon', icon: '📱', amount: 0, frequency: 'monthly' },
                { id: 'aidat', name: 'Aidat', icon: '🏢', amount: 0, frequency: 'monthly' },
                { id: 'servis', name: 'Servis Ücreti', icon: '🚐', amount: 0, frequency: 'monthly' },
                { id: 'arac_yakit', name: 'Araç Yakıtı', icon: '⛽', amount: 0, frequency: 'monthly' },
                { id: 'sgk_bagkur', name: 'SGK & Bağkur', icon: '🏥', amount: 0, frequency: 'monthly' },
                { id: 'okul_taksit', name: 'Okul Taksidi', icon: '🎓', amount: 0, frequency: 'monthly' },
                { id: 'kredi_taksit', name: 'Kredi Taksiti', icon: '🏦', amount: 0, frequency: 'monthly' },
                { id: 'kredi_karti', name: 'Kredi Kartı', icon: '💳', amount: 0, frequency: 'monthly' },
                { id: 'gym_monthly', name: 'Spor Salonu (Aylık)', icon: '💪', amount: 0, frequency: 'monthly' },
                { id: 'dijital_abonelikler', name: 'Dijital Abonelikler', icon: '📺', amount: 0, frequency: 'monthly' }
            ],
            
            predefinedYearly: [
                { id: 'arac_bakim', name: 'Araç Bakımı', icon: '🔧', amount: 0, frequency: 'yearly' },
                { id: 'arac_sigorta', name: 'Araç Sigortası', icon: '🚗', amount: 0, frequency: 'yearly' },
                { id: 'mtv', name: 'MTV', icon: '📄', amount: 0, frequency: 'yearly' },
                { id: 'arac_kasko', name: 'Araç Kaskosu', icon: '🛡️', amount: 0, frequency: 'yearly' },
                { id: 'arac_muayene', name: 'Araç Muayenesi', icon: '🔍', amount: 0, frequency: 'yearly' },
                { id: 'dask', name: 'DASK', icon: '🏠', amount: 0, frequency: 'yearly' },
                { id: 'saglik_sigorta', name: 'Sağlık Sigortası', icon: '🏥', amount: 0, frequency: 'yearly' },
                { id: 'emlak_vergi', name: 'Emlak Vergisi', icon: '🏛️', amount: 0, frequency: 'yearly' },
                { id: 'tatil', name: 'Tatil Masrafı', icon: '🏖️', amount: 0, frequency: 'yearly' },
                { id: 'gym_yearly', name: 'Spor Salonu (Yıllık)', icon: '🏋️', amount: 0, frequency: 'yearly' }
            ],
            
            // Custom categories
            customDaily: [],
            customMonthly: [],
            customYearly: [],
            
            // Income data structures (mirroring expense structure)
            predefinedDailyIncome: [
                { id: 'maas', name: 'Maaş', icon: '💼', amount: 0, frequency: 'daily' },
                { id: 'freelance', name: 'Freelance', icon: '💻', amount: 0, frequency: 'daily' },
                { id: 'yatirim', name: 'Yatırım', icon: '📈', amount: 0, frequency: 'daily' },
                { id: 'diger_gelir', name: 'Diğer', icon: '💰', amount: 0, frequency: 'daily' },
            ],
            
            predefinedMonthlyIncome: [
                { id: 'aylik_maas', name: 'Aylık Maaş', icon: '💼', amount: 0, frequency: 'monthly' },
                { id: 'kira_geliri', name: 'Kira Geliri', icon: '🏠', amount: 0, frequency: 'monthly' },
                { id: 'pasif_gelir', name: 'Pasif Gelir', icon: '🔄', amount: 0, frequency: 'monthly' },
                { id: 'bonus', name: 'Bonus', icon: '🎁', amount: 0, frequency: 'monthly' },
                { id: 'komisyon', name: 'Komisyon', icon: '💵', amount: 0, frequency: 'monthly' },
                { id: 'dijital_urun', name: 'Dijital Ürün', icon: '💿', amount: 0, frequency: 'monthly' },
                { id: 'egitim', name: 'Eğitim', icon: '🎓', amount: 0, frequency: 'monthly' },
                { id: 'danismanlik', name: 'Danışmanlık', icon: '🤝', amount: 0, frequency: 'monthly' },
                { id: 'sosyal_medya', name: 'Sosyal Medya', icon: '📱', amount: 0, frequency: 'monthly' },
                { id: 'youtube', name: 'YouTube', icon: '📺', amount: 0, frequency: 'monthly' },
                { id: 'blog', name: 'Blog', icon: '📝', amount: 0, frequency: 'monthly' },
                { id: 'podcast', name: 'Podcast', icon: '🎙️', amount: 0, frequency: 'monthly' },
                { id: 'online_kurs', name: 'Online Kurs', icon: '💻', amount: 0, frequency: 'monthly' },
                { id: 'affiliate', name: 'Affiliate', icon: '🔗', amount: 0, frequency: 'monthly' },
                { id: 'diger_aylik', name: 'Diğer', icon: '💎', amount: 0, frequency: 'monthly' }
            ],
            
            predefinedYearlyIncome: [
                { id: 'yillik_bonus', name: 'Yıllık Bonus', icon: '🎁', amount: 0, frequency: 'yearly' },
                { id: 'yatirim_getirisi', name: 'Yatırım Getirisi', icon: '📊', amount: 0, frequency: 'yearly' },
                { id: 'emlak_satisi', name: 'Emlak Satışı', icon: '🏘️', amount: 0, frequency: 'yearly' },
                { id: 'arac_satisi', name: 'Araç Satışı', icon: '🚗', amount: 0, frequency: 'yearly' },
                { id: 'miras', name: 'Miras', icon: '👑', amount: 0, frequency: 'yearly' },
                { id: 'hediye', name: 'Hediye', icon: '🎁', amount: 0, frequency: 'yearly' },
                { id: 'ikramiye', name: 'İkramiye', icon: '💸', amount: 0, frequency: 'yearly' },
                { id: 'telif', name: 'Telif', icon: '📚', amount: 0, frequency: 'yearly' },
                { id: 'patent', name: 'Patent', icon: '⚡', amount: 0, frequency: 'yearly' },
                { id: 'diger_yillik', name: 'Diğer', icon: '💎', amount: 0, frequency: 'yearly' }
            ],
            
            // Custom income categories
            customDailyIncome: [],
            customMonthlyIncome: [],
            customYearlyIncome: [],
            
            // Income live counter variables
            liveIncome: 0,
            liveIncomeCounterKey: 0,
            
            // Counter for unique IDs
            nextCustomId: 1,
            
            // Target amount for savings goal
            targetAmount: 0
        }
    },
    
    computed: {
        // Get all daily expenses (predefined + custom)
        dailyExpenses() {
            return [...this.predefinedDaily, ...this.customDaily].filter(exp => exp.amount > 0);
        },
        
        // Get all monthly expenses (predefined + custom)
        monthlyExpenses() {
            return [...this.predefinedMonthly, ...this.customMonthly].filter(exp => exp.amount > 0);
        },
        
        // Get all yearly expenses (predefined + custom)
        yearlyExpenses() {
            return [...this.predefinedYearly, ...this.customYearly].filter(exp => exp.amount > 0);
        },
        
        // Calculate daily total
        dailyTotal() {
            return this.predefinedDaily.reduce((sum, exp) => sum + (exp.amount || 0), 0) +
                   this.customDaily.reduce((sum, exp) => sum + (exp.amount || 0), 0);
        },
        
        // Calculate monthly total
        monthlyTotal() {
            return this.predefinedMonthly.reduce((sum, exp) => sum + (exp.amount || 0), 0) +
                   this.customMonthly.reduce((sum, exp) => sum + (exp.amount || 0), 0);
        },
        
        // Calculate yearly total
        yearlyTotal() {
            return this.predefinedYearly.reduce((sum, exp) => sum + (exp.amount || 0), 0) +
                   this.customYearly.reduce((sum, exp) => sum + (exp.amount || 0), 0);
        },
        
        // Calculate total monthly expense (daily * 30 + monthly + yearly/12)
        totalMonthlyExpense() {
            return (this.dailyTotal * 30) + this.monthlyTotal + (this.yearlyTotal / 12);
        },
        
        // Calculate daily expense total (including converted monthly and yearly)
        dailyExpenseTotal() {
            return this.dailyTotal + (this.monthlyTotal / 30) + (this.yearlyTotal / 365);
        },
        
        // Calculate hourly expense
        hourlyExpense() {
            return this.dailyExpenseTotal / 24;
        },
        
        // Calculate weekly expense
        weeklyExpense() {
            return this.dailyExpenseTotal * 7;
        },
        
        // Calculate percentages for meters
        dailyPercentage() {
            const maxDaily = 500; // Maximum expected daily expense for meter
            return Math.min(100, (this.dailyTotal / maxDaily) * 100);
        },
        
        monthlyPercentage() {
            const maxMonthly = 10000; // Maximum expected monthly expense for meter
            return Math.min(100, (this.monthlyTotal / maxMonthly) * 100);
        },
        
        // Income computed properties (mirroring expense structure)
        // Get all daily incomes (predefined + custom)
        dailyIncomes() {
            return [...this.predefinedDailyIncome, ...this.customDailyIncome].filter(inc => inc.amount > 0);
        },
        
        // Get all monthly incomes (predefined + custom)
        monthlyIncomes() {
            return [...this.predefinedMonthlyIncome, ...this.customMonthlyIncome].filter(inc => inc.amount > 0);
        },
        
        // Get all yearly incomes (predefined + custom)
        yearlyIncomes() {
            return [...this.predefinedYearlyIncome, ...this.customYearlyIncome].filter(inc => inc.amount > 0);
        },
        
        // Calculate daily income total
        dailyIncomeTotal() {
            return this.predefinedDailyIncome.reduce((sum, inc) => sum + (inc.amount || 0), 0) +
                   this.customDailyIncome.reduce((sum, inc) => sum + (inc.amount || 0), 0);
        },
        
        // Calculate monthly income total
        monthlyIncomeTotal() {
            return this.predefinedMonthlyIncome.reduce((sum, inc) => sum + (inc.amount || 0), 0) +
                   this.customMonthlyIncome.reduce((sum, inc) => sum + (inc.amount || 0), 0);
        },
        
        // Calculate yearly income total
        yearlyIncomeTotal() {
            return this.predefinedYearlyIncome.reduce((sum, inc) => sum + (inc.amount || 0), 0) +
                   this.customYearlyIncome.reduce((sum, inc) => sum + (inc.amount || 0), 0);
        },
        
        // Calculate total monthly income (daily * 30 + monthly + yearly/12)
        totalMonthlyIncome() {
            return (this.dailyIncomeTotal * 30) + this.monthlyIncomeTotal + (this.yearlyIncomeTotal / 12);
        },
        
        // Calculate daily income total (including converted monthly and yearly)
        dailyIncomeTotalConverted() {
            return this.dailyIncomeTotal + (this.monthlyIncomeTotal / 30) + (this.yearlyIncomeTotal / 365);
        },
        
        // Calculate hourly income
        hourlyIncome() {
            return this.dailyIncomeTotalConverted / 24;
        },
        
        // Calculate weekly income
        weeklyIncome() {
            return this.dailyIncomeTotalConverted * 7;
        },
        
        // Calculate percentages for income meters
        dailyIncomePercentage() {
            const maxDaily = 500; // Maximum expected daily income for meter
            return Math.min(100, (this.dailyIncomeTotal / maxDaily) * 100);
        },
        
        monthlyIncomePercentage() {
            const maxMonthly = 10000; // Maximum expected monthly income for meter
            return Math.min(100, (this.monthlyIncomeTotal / maxMonthly) * 100);
        },
        
        // Net Flow Computed Properties
        netFlow() {
            return this.totalMonthlyIncome - this.totalMonthlyExpense;
        },
        
        netDailyFlow() {
            return this.dailyIncomeTotalConverted - this.dailyExpenseTotal;
        },
        
        netHourlyFlow() {
            return this.hourlyIncome - this.hourlyExpense;
        },
        
        netWeeklyFlow() {
            return this.weeklyIncome - this.weeklyExpense;
        },
        
        liveNetFlow() {
            return this.liveIncome - this.liveExpense;
        },
        
        // Financial Health Score
        financialHealthScore() {
            if (this.totalMonthlyExpense === 0) {
                return { score: 10, text: "Mükemmel", color: "green", description: "Hiç gideriniz yok!" };
            }
            
            const ratio = this.totalMonthlyIncome / this.totalMonthlyExpense;
            
            if (ratio >= 2) {
                return { score: 10, text: "Mükemmel", color: "green", description: "Geliriniz giderinizin 2 katından fazla" };
            } else if (ratio >= 1.5) {
                return { score: 8, text: "İyi", color: "blue", description: "Geliriniz giderinizin %50 fazlası" };
            } else if (ratio >= 1.2) {
                return { score: 6, text: "Orta", color: "yellow", description: "Geliriniz giderinizin %20 fazlası" };
            } else if (ratio >= 1) {
                return { score: 4, text: "Zayıf", color: "orange", description: "Gelir ve gideriniz eşit" };
            } else {
                return { score: 2, text: "Kötü", color: "red", description: "Gideriniz gelirinizden fazla" };
            }
        },
        
        // Target Time Calculation
        targetTime() {
            if (!this.targetAmount || this.targetAmount <= 0) {
                return { hours: 0, days: 0, weeks: 0, months: 0, years: 0 };
            }
            
            if (this.netFlow <= 0) {
                return { 
                    hours: 0, 
                    days: 0, 
                    weeks: 0, 
                    months: 0, 
                    years: 0,
                    message: "Net akışınız negatif! Hedefe ulaşamazsınız."
                };
            }
            
            const hours = this.targetAmount / this.netHourlyFlow;
            const days = hours / 24;
            const weeks = days / 7;
            const months = days / 30.44; // Gerçek ortalama ay (365.25/12)
            const years = days / 365.25; // Artık yıllar dahil
            
            return {
                hours: Math.round(hours * 100) / 100,
                days: Math.round(days * 100) / 100,
                weeks: Math.round(weeks * 100) / 100,
                months: Math.round(months * 100) / 100,
                years: Math.round(years * 100) / 100
            };
        },

        // Dynamic session time text based on active tab and financial situation
        dynamicSessionTime() {
            const timeText = this.sessionTime.replace('cebinizden çıkan para', '').replace('cebinize giren para', '');
            
            if (this.activeTab === 'expense') {
                return timeText + 'cebinizden çıkan para';
            } else if (this.activeTab === 'income') {
                return timeText + 'cebinize giren para';
            } else if (this.activeTab === 'summary') {
                if (this.totalMonthlyIncome > this.totalMonthlyExpense) {
                    return timeText + 'cebinize giren para';
                } else {
                    return timeText + 'cebinizden çıkan para';
                }
            }
            
            return this.sessionTime; // fallback
        },

        // Dynamic bar color class based on active tab and financial situation
        dynamicBarColorClass() {
            if (this.activeTab === 'expense') {
                return 'bg-gradient-to-r from-red-500 to-red-600';
            } else if (this.activeTab === 'income') {
                return 'bg-gradient-to-r from-green-500 to-green-600';
            } else if (this.activeTab === 'summary') {
                if (this.totalMonthlyIncome > this.totalMonthlyExpense) {
                    return 'bg-gradient-to-r from-green-500 to-green-600';
                } else {
                    return 'bg-gradient-to-r from-red-500 to-red-600';
                }
            }
            
            return 'bg-gradient-to-r from-gray-500 to-gray-600'; // fallback
        },

        // Dynamic text color class based on active tab and financial situation
        dynamicTextColorClass() {
            if (this.activeTab === 'expense') {
                return 'text-red-100';
            } else if (this.activeTab === 'income') {
                return 'text-green-100';
            } else if (this.activeTab === 'summary') {
                if (this.totalMonthlyIncome > this.totalMonthlyExpense) {
                    return 'text-green-100';
                } else {
                    return 'text-red-100';
                }
            }
            
            return 'text-gray-100'; // fallback
        },

        // Dynamic amount color class based on active tab and financial situation
        dynamicAmountColorClass() {
            if (this.activeTab === 'expense') {
                return 'text-red-400';
            } else if (this.activeTab === 'income') {
                return 'text-green-400';
            } else if (this.activeTab === 'summary') {
                if (this.totalMonthlyIncome > this.totalMonthlyExpense) {
                    return 'text-green-400';
                } else {
                    return 'text-red-400';
                }
            }
            
            return 'text-gray-400'; // fallback
        },

        // Dynamic amount value based on active tab and financial situation
        dynamicAmountValue() {
            if (this.activeTab === 'expense') {
                return Math.abs(this.liveExpense);
            } else if (this.activeTab === 'income') {
                return Math.abs(this.liveIncome);
            } else if (this.activeTab === 'summary') {
                return this.liveNetFlow; // Keep original sign for summary
            }
            
            return 0; // fallback
        }
    },
    
    mounted() {
        this.loadData();
        this.startSessionTimer();
        this.startLiveNetCounter();
    },
    
    beforeUnmount() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
        }
        if (this.liveExpenseIntervalId) {
            clearInterval(this.liveExpenseIntervalId);
        }
        if (this.liveIncomeIntervalId) {
            clearInterval(this.liveIncomeIntervalId);
        }
    },
    
    methods: {
        // Format plain numeric amount into input-friendly string with thousand separators (e.g., 123.456.789)
        formatInput(amount) {
            const numericAmount = Number(amount || 0);
            const sign = numericAmount < 0 ? '-' : '';
            const abs = Math.floor(Math.abs(numericAmount));
            const formatted = abs.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');
            return sign + formatted;
        },

        // Parse any input string into a non-decimal integer amount by stripping non-digits
        parseAmountFromInput(inputValue) {
            const digits = (inputValue || '').toString().replace(/\D/g, '');
            return Number(digits || 0);
        },

        // Unified input handler for all amount inputs (daily/monthly/yearly + custom)
        onAmountInput(category, rawValue) {
            const parsed = this.parseAmountFromInput(rawValue);
            // Update local object
            category.amount = parsed;

            // Persist to correct bucket using existing helpers
            const isDaily = !!this.predefinedDaily.find(c => c.id === category.id) || !!this.customDaily.find(c => c.id === category.id);
            const isMonthly = !!this.predefinedMonthly.find(c => c.id === category.id) || !!this.customMonthly.find(c => c.id === category.id);
            const isYearly = (!!this.predefinedYearly && !!this.predefinedYearly.find(c => c.id === category.id)) || (!!this.customYearly && !!this.customYearly.find(c => c.id === category.id));

            if (isDaily || isMonthly || isYearly) {
                // Try predefined first
                if (this.predefinedDaily.find(c => c.id === category.id) || this.predefinedMonthly.find(c => c.id === category.id) || (this.predefinedYearly && this.predefinedYearly.find(c => c.id === category.id))) {
                    this.updateExpense(category.id, parsed);
                } else {
                    // Custom categories
                    this.updateCustomCategory(category.id, category.name, parsed);
                }
            }

            this.calculateLiveExpense();
            this.saveData();
        },

        // Unified input handler for all income inputs (daily/monthly/yearly + custom)
        onIncomeInput(category, rawValue) {
            const parsed = this.parseAmountFromInput(rawValue);
            // Update local object
            category.amount = parsed;

            // Persist to correct bucket using income helpers
            const isDaily = !!this.predefinedDailyIncome.find(c => c.id === category.id) || !!this.customDailyIncome.find(c => c.id === category.id);
            const isMonthly = !!this.predefinedMonthlyIncome.find(c => c.id === category.id) || !!this.customMonthlyIncome.find(c => c.id === category.id);
            const isYearly = (!!this.predefinedYearlyIncome && !!this.predefinedYearlyIncome.find(c => c.id === category.id)) || (!!this.customYearlyIncome && !!this.customYearlyIncome.find(c => c.id === category.id));

            if (isDaily || isMonthly || isYearly) {
                // Try predefined first
                if (this.predefinedDailyIncome.find(c => c.id === category.id) || this.predefinedMonthlyIncome.find(c => c.id === category.id) || (this.predefinedYearlyIncome && this.predefinedYearlyIncome.find(c => c.id === category.id))) {
                    this.updateIncome(category.id, parsed);
                } else {
                    // Custom categories
                    this.updateCustomIncomeCategory(category.id, category.name, parsed);
                }
            }

            this.calculateLiveIncome();
            this.saveData();
        },

        // Format currency to Turkish Lira with kuruş
        formatCurrency(amount) {
            return new Intl.NumberFormat('tr-TR', {
                style: 'currency',
                currency: 'TRY',
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            }).format(amount || 0);
        },
        
        // Start the session timer that updates every second
        startSessionTimer() {
            this.updateSessionTime();
            this.intervalId = setInterval(() => {
                this.updateSessionTime();
            }, 1000);
        },
        
        // Start live expense counter that updates 10 times per second
        startLiveExpenseCounter() {
            this.calculateLiveExpense();
            this.liveExpenseIntervalId = setInterval(() => {
                this.calculateLiveExpense();
                this.liveCounterKey++; // Force re-render for animation
            }, 100); // 100ms = 10 times per second
        },
        
        // Start live income counter that updates 10 times per second
        startLiveIncomeCounter() {
            this.calculateLiveIncome();
            this.liveIncomeIntervalId = setInterval(() => {
                this.calculateLiveIncome();
                this.liveIncomeCounterKey++; // Force re-render for animation
            }, 100); // 100ms = 10 times per second
        },
        
        // Start unified live counter that updates 10 times per second
        startLiveNetCounter() {
            this.calculateLiveExpense();
            this.calculateLiveIncome();
            this.liveExpenseIntervalId = setInterval(() => {
                this.calculateLiveExpense();
                this.calculateLiveIncome();
                this.liveCounterKey++; // Force re-render for animation
            }, 100); // 100ms = 10 times per second
        },
        
        // Update session time display
        updateSessionTime() {
            const now = new Date();
            const timeDiff = now - this.sessionStartTime;
            
            const hours = Math.floor(timeDiff / (1000 * 60 * 60));
            const minutes = Math.floor((timeDiff % (1000 * 60 * 60)) / (1000 * 60));
            const seconds = Math.floor((timeDiff % (1000 * 60)) / 1000);
            
            // Smart time formatting - only show non-zero values
            let timeString = "Son ";
            let parts = [];
            
            if (hours > 0) {
                parts.push(`${hours} saat`);
            }
            if (minutes > 0) {
                parts.push(`${minutes} dakika`);
            }
            if (seconds > 0 || parts.length === 0) { // Always show seconds if nothing else
                parts.push(`${seconds} saniye`);
            }
            
            // Join parts with commas
            if (parts.length === 1) {
                timeString += parts[0];
            } else if (parts.length === 2) {
                timeString += parts.join(", ");
            } else {
                timeString += parts.slice(0, -1).join(", ") + ", " + parts[parts.length - 1];
            }
            
            this.sessionTime = timeString + "de cebinizden çıkan para";
        },
        
        // Calculate live expense based on session time
        calculateLiveExpense() {
            const now = new Date();
            const sessionSeconds = (now - this.sessionStartTime) / 1000;
            
            // Calculate expense per second (more precise calculation)
            const dailyExpensePerSecond = this.dailyTotal / (24 * 60 * 60); // Daily expense per second
            const monthlyExpensePerSecond = this.monthlyTotal / (30 * 24 * 60 * 60); // Monthly expense per second
            const yearlyExpensePerSecond = this.yearlyTotal / (365 * 24 * 60 * 60); // Yearly expense per second
            
            // Calculate live expense with kuruş precision
            this.liveExpense = (dailyExpensePerSecond + monthlyExpensePerSecond + yearlyExpensePerSecond) * sessionSeconds;
            
            // Round to 2 decimal places for kuruş precision
            this.liveExpense = Math.round(this.liveExpense * 100) / 100;
        },
        
        // Calculate live income based on session time (mirroring expense logic)
        calculateLiveIncome() {
            const now = new Date();
            const sessionSeconds = (now - this.sessionStartTime) / 1000;
            
            // Calculate income per second (more precise calculation)
            const dailyIncomePerSecond = this.dailyIncomeTotal / (24 * 60 * 60); // Daily income per second
            const monthlyIncomePerSecond = this.monthlyIncomeTotal / (30 * 24 * 60 * 60); // Monthly income per second
            const yearlyIncomePerSecond = this.yearlyIncomeTotal / (365 * 24 * 60 * 60); // Yearly income per second
            
            // Calculate live income with kuruş precision
            this.liveIncome = (dailyIncomePerSecond + monthlyIncomePerSecond + yearlyIncomePerSecond) * sessionSeconds;
            
            // Round to 2 decimal places for kuruş precision
            this.liveIncome = Math.round(this.liveIncome * 100) / 100;
        },
        
        // Update expense amount
        updateExpense(categoryId, amount) {
            const predefinedDaily = this.predefinedDaily.find(cat => cat.id === categoryId);
            if (predefinedDaily) {
                predefinedDaily.amount = Number(amount) || 0;
            } else {
                const predefinedMonthly = this.predefinedMonthly.find(cat => cat.id === categoryId);
                if (predefinedMonthly) {
                    predefinedMonthly.amount = Number(amount) || 0;
                } else {
                    const predefinedYearly = this.predefinedYearly.find(cat => cat.id === categoryId);
                    if (predefinedYearly) {
                        predefinedYearly.amount = Number(amount) || 0;
                    }
                }
            }
            this.calculateLiveExpense(); // Recalculate when expense changes
            this.saveData();
        },

        // Update income amount (mirroring expense logic)
        updateIncome(categoryId, amount) {
            const predefinedDaily = this.predefinedDailyIncome.find(cat => cat.id === categoryId);
            if (predefinedDaily) {
                predefinedDaily.amount = Number(amount) || 0;
            } else {
                const predefinedMonthly = this.predefinedMonthlyIncome.find(cat => cat.id === categoryId);
                if (predefinedMonthly) {
                    predefinedMonthly.amount = Number(amount) || 0;
                } else {
                    const predefinedYearly = this.predefinedYearlyIncome.find(cat => cat.id === categoryId);
                    if (predefinedYearly) {
                        predefinedYearly.amount = Number(amount) || 0;
                    }
                }
            }
            this.calculateLiveIncome(); // Recalculate when income changes
            this.saveData();
        },
        
        // Remove expense (reset to 0)
        removeExpense(categoryId) {
            const predefinedDaily = this.predefinedDaily.find(cat => cat.id === categoryId);
            if (predefinedDaily) {
                predefinedDaily.amount = 0;
            } else {
                const predefinedMonthly = this.predefinedMonthly.find(cat => cat.id === categoryId);
                if (predefinedMonthly) {
                    predefinedMonthly.amount = 0;
                } else {
                    const predefinedYearly = this.predefinedYearly.find(cat => cat.id === categoryId);
                    if (predefinedYearly) {
                        predefinedYearly.amount = 0;
                    }
                }
            }
            this.calculateLiveExpense();
            this.saveData();
        },

        // Remove income (reset to 0) - mirroring expense logic
        removeIncome(categoryId) {
            const predefinedDaily = this.predefinedDailyIncome.find(cat => cat.id === categoryId);
            if (predefinedDaily) {
                predefinedDaily.amount = 0;
            } else {
                const predefinedMonthly = this.predefinedMonthlyIncome.find(cat => cat.id === categoryId);
                if (predefinedMonthly) {
                    predefinedMonthly.amount = 0;
                } else {
                    const predefinedYearly = this.predefinedYearlyIncome.find(cat => cat.id === categoryId);
                    if (predefinedYearly) {
                        predefinedYearly.amount = 0;
                    }
                }
            }
            this.calculateLiveIncome();
            this.saveData();
        },
        
        // Add custom daily category
        addCustomDaily() {
            const newCategory = {
                id: `custom_daily_${this.nextCustomId++}`,
                name: '',
                amount: 0,
                frequency: 'daily'
            };
            this.customDaily.push(newCategory);
            this.saveData();
        },
        
        // Add custom monthly category
        addCustomMonthly() {
            const newCategory = {
                id: `custom_monthly_${this.nextCustomId++}`,
                name: '',
                amount: 0,
                frequency: 'monthly'
            };
            this.customMonthly.push(newCategory);
            this.saveData();
        },
        
        // Add custom yearly category
        addCustomYearly() {
            const newCategory = {
                id: `custom_yearly_${this.nextCustomId++}`,
                name: '',
                amount: 0,
                frequency: 'yearly'
            };
            this.customYearly.push(newCategory);
            this.saveData();
        },

        // Add custom daily income category (mirroring expense logic)
        addCustomDailyIncome() {
            const newCategory = {
                id: `custom_daily_income_${this.nextCustomId++}`,
                name: '',
                amount: 0,
                frequency: 'daily'
            };
            this.customDailyIncome.push(newCategory);
            this.saveData();
        },

        // Add custom monthly income category (mirroring expense logic)
        addCustomMonthlyIncome() {
            const newCategory = {
                id: `custom_monthly_income_${this.nextCustomId++}`,
                name: '',
                amount: 0,
                frequency: 'monthly'
            };
            this.customMonthlyIncome.push(newCategory);
            this.saveData();
        },

        // Add custom yearly income category (mirroring expense logic)
        addCustomYearlyIncome() {
            const newCategory = {
                id: `custom_yearly_income_${this.nextCustomId++}`,
                name: '',
                amount: 0,
                frequency: 'yearly'
            };
            this.customYearlyIncome.push(newCategory);
            this.saveData();
        },
        
        // Update custom category
        updateCustomCategory(categoryId, name, amount) {
            const dailyCategory = this.customDaily.find(cat => cat.id === categoryId);
            if (dailyCategory) {
                dailyCategory.name = name;
                dailyCategory.amount = Number(amount) || 0;
            } else {
                const monthlyCategory = this.customMonthly.find(cat => cat.id === categoryId);
                if (monthlyCategory) {
                    monthlyCategory.name = name;
                    monthlyCategory.amount = Number(amount) || 0;
                } else {
                    const yearlyCategory = this.customYearly.find(cat => cat.id === categoryId);
                    if (yearlyCategory) {
                        yearlyCategory.name = name;
                        yearlyCategory.amount = Number(amount) || 0;
                    }
                }
            }
            this.calculateLiveExpense(); // Recalculate when expense changes
            this.saveData();
        },

        // Update custom income category (mirroring expense logic)
        updateCustomIncomeCategory(categoryId, name, amount) {
            const dailyCategory = this.customDailyIncome.find(cat => cat.id === categoryId);
            if (dailyCategory) {
                dailyCategory.name = name;
                dailyCategory.amount = Number(amount) || 0;
            } else {
                const monthlyCategory = this.customMonthlyIncome.find(cat => cat.id === categoryId);
                if (monthlyCategory) {
                    monthlyCategory.name = name;
                    monthlyCategory.amount = Number(amount) || 0;
                } else {
                    const yearlyCategory = this.customYearlyIncome.find(cat => cat.id === categoryId);
                    if (yearlyCategory) {
                        yearlyCategory.name = name;
                        yearlyCategory.amount = Number(amount) || 0;
                    }
                }
            }
            this.calculateLiveIncome(); // Recalculate when income changes
            this.saveData();
        },
        
        // Remove custom category
        removeCustomCategory(categoryId) {
            this.customDaily = this.customDaily.filter(cat => cat.id !== categoryId);
            this.customMonthly = this.customMonthly.filter(cat => cat.id !== categoryId);
            this.customYearly = this.customYearly.filter(cat => cat.id !== categoryId);
            this.saveData();
        },

        // Remove custom income category (mirroring expense logic)
        removeCustomIncomeCategory(categoryId) {
            this.customDailyIncome = this.customDailyIncome.filter(cat => cat.id !== categoryId);
            this.customMonthlyIncome = this.customMonthlyIncome.filter(cat => cat.id !== categoryId);
            this.customYearlyIncome = this.customYearlyIncome.filter(cat => cat.id !== categoryId);
            this.saveData();
        },
        
        // Clear all data
        clearAllData() {
            if (confirm('Tüm verilerinizi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.')) {
                // Reset predefined expense categories
                this.predefinedDaily.forEach(cat => cat.amount = 0);
                this.predefinedMonthly.forEach(cat => cat.amount = 0);
                this.predefinedYearly.forEach(cat => cat.amount = 0);
                
                // Clear custom expense categories
                this.customDaily = [];
                this.customMonthly = [];
                this.customYearly = [];
                
                // Reset predefined income categories
                this.predefinedDailyIncome.forEach(cat => cat.amount = 0);
                this.predefinedMonthlyIncome.forEach(cat => cat.amount = 0);
                this.predefinedYearlyIncome.forEach(cat => cat.amount = 0);
                
                // Clear custom income categories
                this.customDailyIncome = [];
                this.customMonthlyIncome = [];
                this.customYearlyIncome = [];
                
                // Reset counter
                this.nextCustomId = 1;
                
                this.saveData();
            }
        },
        
        // Export data to Excel/CSV
        exportData() {
            const data = {
                'Giderler': {
                    'Günlük': this.dailyExpenseTotal,
                    'Aylık': this.totalMonthlyExpense,
                    'Yıllık': this.yearlyTotal
                },
                'Gelirler': {
                    'Günlük': this.dailyIncomeTotalConverted,
                    'Aylık': this.totalMonthlyIncome,
                    'Yıllık': this.yearlyIncomeTotal
                },
                'Net Akış': {
                    'Günlük': this.netDailyFlow,
                    'Aylık': this.netFlow
                },
                'Finansal Sağlık': {
                    'Skor': this.financialHealthScore.score + '/10',
                    'Durum': this.financialHealthScore.text
                }
            };
            
            const csv = this.convertToCSV(data);
            this.downloadFile(csv, 'butce-raporu.csv', 'text/csv');
        },
        
        // Backup data to JSON
        backupData() {
            const data = {
                predefinedDaily: this.predefinedDaily,
                predefinedMonthly: this.predefinedMonthly,
                predefinedYearly: this.predefinedYearly,
                customDaily: this.customDaily,
                customMonthly: this.customMonthly,
                customYearly: this.customYearly,
                predefinedDailyIncome: this.predefinedDailyIncome,
                predefinedMonthlyIncome: this.predefinedMonthlyIncome,
                predefinedYearlyIncome: this.predefinedYearlyIncome,
                customDailyIncome: this.customDailyIncome,
                customMonthlyIncome: this.customMonthlyIncome,
                customYearlyIncome: this.customYearlyIncome,
                nextCustomId: this.nextCustomId,
                exportDate: new Date().toISOString()
            };
            
            this.downloadFile(JSON.stringify(data, null, 2), 'butce-yedek.json', 'application/json');
        },
        
        // Convert data to CSV format
        convertToCSV(data) {
            let csv = 'Kategori,Değer\n';
            for (const [category, values] of Object.entries(data)) {
                for (const [key, value] of Object.entries(values)) {
                    csv += `${category} - ${key},"${value}"\n`;
                }
            }
            return csv;
        },
        
        // Download file helper
        downloadFile(content, filename, mimeType) {
            const blob = new Blob([content], { type: mimeType });
            const url = URL.createObjectURL(blob);
            const link = document.createElement('a');
            link.href = url;
            link.download = filename;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            URL.revokeObjectURL(url);
        },
        
        // Save data to localStorage
        saveData() {
            const data = {
                predefinedDaily: this.predefinedDaily,
                predefinedMonthly: this.predefinedMonthly,
                predefinedYearly: this.predefinedYearly,
                customDaily: this.customDaily,
                customMonthly: this.customMonthly,
                customYearly: this.customYearly,
                predefinedDailyIncome: this.predefinedDailyIncome,
                predefinedMonthlyIncome: this.predefinedMonthlyIncome,
                predefinedYearlyIncome: this.predefinedYearlyIncome,
                customDailyIncome: this.customDailyIncome,
                customMonthlyIncome: this.customMonthlyIncome,
                customYearlyIncome: this.customYearlyIncome,
                nextCustomId: this.nextCustomId
            };
            localStorage.setItem('gidermetre_data', JSON.stringify(data));
        },
        
        // Load data from localStorage
        loadData() {
            const savedData = localStorage.getItem('gidermetre_data');
            if (savedData) {
                try {
                    const data = JSON.parse(savedData);
                    
                    // Load predefined categories (preserve structure, only load amounts)
                    if (data.predefinedDaily) {
                        data.predefinedDaily.forEach(savedCat => {
                            const existingCat = this.predefinedDaily.find(cat => cat.id === savedCat.id);
                            if (existingCat) {
                                existingCat.amount = savedCat.amount || 0;
                            }
                        });
                    }
                    
                    if (data.predefinedMonthly) {
                        data.predefinedMonthly.forEach(savedCat => {
                            const existingCat = this.predefinedMonthly.find(cat => cat.id === savedCat.id);
                            if (existingCat) {
                                existingCat.amount = savedCat.amount || 0;
                            }
                        });
                    }
                    
                    if (data.predefinedYearly) {
                        data.predefinedYearly.forEach(savedCat => {
                            const existingCat = this.predefinedYearly.find(cat => cat.id === savedCat.id);
                            if (existingCat) {
                                existingCat.amount = savedCat.amount || 0;
                            }
                        });
                    }
                    
                    // Load custom expense categories
                    if (data.customDaily) {
                        this.customDaily = data.customDaily;
                    }
                    
                    if (data.customMonthly) {
                        this.customMonthly = data.customMonthly;
                    }
                    
                    if (data.customYearly) {
                        this.customYearly = data.customYearly;
                    }
                    
                    // Load predefined income categories (preserve structure, only load amounts)
                    if (data.predefinedDailyIncome) {
                        data.predefinedDailyIncome.forEach(savedCat => {
                            const existingCat = this.predefinedDailyIncome.find(cat => cat.id === savedCat.id);
                            if (existingCat) {
                                existingCat.amount = savedCat.amount || 0;
                            }
                        });
                    }
                    
                    if (data.predefinedMonthlyIncome) {
                        data.predefinedMonthlyIncome.forEach(savedCat => {
                            const existingCat = this.predefinedMonthlyIncome.find(cat => cat.id === savedCat.id);
                            if (existingCat) {
                                existingCat.amount = savedCat.amount || 0;
                            }
                        });
                    }
                    
                    if (data.predefinedYearlyIncome) {
                        data.predefinedYearlyIncome.forEach(savedCat => {
                            const existingCat = this.predefinedYearlyIncome.find(cat => cat.id === savedCat.id);
                            if (existingCat) {
                                existingCat.amount = savedCat.amount || 0;
                            }
                        });
                    }
                    
                    // Load custom income categories
                    if (data.customDailyIncome) {
                        this.customDailyIncome = data.customDailyIncome;
                    }
                    
                    if (data.customMonthlyIncome) {
                        this.customMonthlyIncome = data.customMonthlyIncome;
                    }
                    
                    if (data.customYearlyIncome) {
                        this.customYearlyIncome = data.customYearlyIncome;
                    }
                    
                    // Load counter
                    if (data.nextCustomId) {
                        this.nextCustomId = data.nextCustomId;
                    }
                } catch (error) {
                    console.error('Error loading saved data:', error);
                }
            }
        }
    }
}).mount('#app');
